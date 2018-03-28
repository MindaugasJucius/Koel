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

private let KoelSpotifySessionUserDefaultsKey = "koel_spotify_session"

let SpotifyURLCallbackNotification = Notification.Name("SpotifyURLCallbackNotification")
let SpotifyURLCallbackNotificationUserInfoURLKey = "SpotifyURLCallbackNotificationUserInfoURLKey"

class DMSpotifyAuthService: NSObject {

    let sceneCoordinator: SceneCoordinatorType
    
    private let disposeBag = DisposeBag()
    private let auth: SPTAuth = SPTAuth.defaultInstance()
    //private let player: SPTAudioStreamingController = SPTAudioStreamingController.sharedInstance()
    
    var authenticationIsNeeded: Bool {
        return auth.session == nil || !auth.session.isValid()
    }
    
    private var sessionObservable: Observable<SPTSession> {
        return currentSession.asObservable()
    }
    
    private var currentSession = ReplaySubject<SPTSession>.create(bufferSize: 1)
    
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
    
    func authentication() -> Observable<SPTSession> {
        
        if auth.session != nil && auth.session.isValid() {
            return Observable<SPTSession>.just(auth.session)
        }
        
        let notificationObservable = NotificationCenter.default.rx
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
        

        if SPTAuth.supportsApplicationAuthentication() {
            UIApplication.shared.open(self.auth.spotifyAppAuthenticationURL(), options: [:])
        } else {
            let authenticationScene = Scene.authenticateSpotify(auth.spotifyWebAuthenticationURL())
            sceneCoordinator.transition(to: authenticationScene, type: .modal)
        }
        
        return
            notificationObservable
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
                            if let error = error {
                                os_log("spotify auth callback error: %@", log: OSLog.default, type: .error, error.localizedDescription)
                                observer.onError(error)
                            } else if let session = session {
                                os_log("access token: %@", log: OSLog.default, type: .info, session.accessToken)
                                os_log("expiration date: %@", log: OSLog.default, type: .info, session.expirationDate.description)
                                observer.onNext(session)
                            }
                            observer.onCompleted()
                        }
                    )
                    return Disposables.create()
                }
            }
    }
}


//extension DMSpotifyService: SPTAudioStreamingPlaybackDelegate {
//
//}
//
//extension DMSpotifyService: SPTAudioStreamingDelegate {
//
//    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
//
//        player.playSpotifyURI("spotify:track:58s6EuEYJdlb0kO7awm3Vp", startingWith: 0, startingWithPosition: 0) { error in
//            guard let error = error else {
//                return
//            }
//            print("audio playing failed due to an error: \(error.localizedDescription)")
//        }
//    }
//}

