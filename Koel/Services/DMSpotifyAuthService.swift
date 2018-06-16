//
//  DMSpotifyService.swift
//  Koel
//
//  Created by Mindaugas Jucius on 27/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import SafariServices
import os.log
import RxSwift
import RxOptional
import Spartan

private let KoelSpotifySessionUserDefaultsKey = "koel_spotify_session"

let SpotifyURLCallbackNotification = Notification.Name("SpotifyURLCallbackNotification")
let SpotifyURLCallbackNotificationUserInfoURLKey = "SpotifyURLCallbackNotificationUserInfoURLKey"

class DMSpotifyAuthService: NSObject {

    typealias SPTAuthCallbackObserver = (Error?, SPTSession?, AnyObserver<SPTSession>) -> ()
    
    let sceneCoordinator: SceneCoordinatorType
    
    private let maxAttempts = 4
    
    private let disposeBag = DisposeBag()
    private let auth: SPTAuth = SPTAuth.defaultInstance()
    
    var authenticationIsNeeded: Bool {
        return auth.session == nil || !auth.session.isValid()
    }
    
    var currentSessionObservable: Observable<SPTSession> {
        return currentSession()
            .do(onNext: { [unowned self] session in
                    Spartan.authorizationToken = session.accessToken
                    self.auth.session = session
                }
            )
    }
    
    
    init(sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
        super.init()
        auth.clientID = "e693a6d7103f4d46ac64eebc6906f8f4"
        auth.sessionUserDefaultsKey = KoelSpotifySessionUserDefaultsKey
        auth.redirectURL = URL(string: "koel://returnafterlogin")
        auth.tokenRefreshURL = URL(string: "https://koel-spotify-auth.herokuapp.com/refresh")
        auth.tokenSwapURL = URL(string: "https://koel-spotify-auth.herokuapp.com/swap")
        auth.requestedScopes = [
            SPTAuthStreamingScope,
            SPTAuthUserReadTopScope,
            SPTAuthUserLibraryReadScope,
            SPTAuthPlaylistReadPrivateScope
        ]
    }
    
    private func currentSession() -> Observable<SPTSession> {
        guard auth.session != nil else {
            return performAuthenticationFlow()
        }
        
        if auth.session.isValid() {
            return Observable<SPTSession>.just(auth.session)
        } else {
            return Observable<SPTSession>.create { [unowned self] observer -> Disposable in
                os_log("renewing spt session", log: OSLog.default, type: .info)
                self.auth.renewSession(self.auth.session, callback: { (error, session) in
                    self.authCallback(error, session, observer)
                })
                return Disposables.create()
            }
        }
    }
    
    private var authCallback: SPTAuthCallbackObserver {
        return { error, session, observer in
            if let error = error {
                print((error as NSError).domain)
                os_log("spotify auth callback error: %@", log: OSLog.default, type: .error, error.localizedDescription)
                observer.onError(error)
            } else if let session = session {
                os_log("access token: %@", log: OSLog.default, type: .info, session.accessToken)
                os_log("expiration date: %@", log: OSLog.default, type: .info, session.expirationDate.description)
                observer.onNext(session)
            }
            observer.onCompleted()
        }
    }
    
    private var authURLNotificationObservable: Observable<URL> {
        return NotificationCenter.default.rx
            .notification(SpotifyURLCallbackNotification)
            .filter { (notification) -> Bool in
                return notification.name == SpotifyURLCallbackNotification
            }
            .map { notification -> URL? in
                guard let userInfo = notification.userInfo,
                    let url = userInfo[SpotifyURLCallbackNotificationUserInfoURLKey] as? URL else {
                        return nil
                }
                return url
            }
            .filterNil()
    }
    
    private func performAuthenticationFlow() -> Observable<SPTSession> {
        if SPTAuth.supportsApplicationAuthentication() {
            UIApplication.shared.open(self.auth.spotifyAppAuthenticationURL(), options: [:])
        } else {
            let authenticationScene = Scene.authenticateSpotify(auth.spotifyWebAuthenticationURL())
            sceneCoordinator.transition(to: authenticationScene, type: .modal)
        }
        
        return authURLNotificationObservable
            .take(1)
            .do(onNext: { [unowned self] _ in
                if self.sceneCoordinator.currentViewController is SFSafariViewController {
                    self.sceneCoordinator.pop()
                }
            })
            .flatMap { [unowned self] callbackURL -> Observable<SPTSession> in
                Observable<SPTSession>.create { observer -> Disposable in
                    self.auth.handleAuthCallback(
                        withTriggeredAuthURL: callbackURL,
                        callback: { (error, session) in
                            self.authCallback(error, session, observer)
                        }
                    )
                    return Disposables.create()
            }
        }
    }
}
