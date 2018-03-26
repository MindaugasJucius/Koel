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
        
        //currentSession.flatMap(<#T##selector: (SPTSession) throws -> ObservableConvertibleType##(SPTSession) throws -> ObservableConvertibleType#>)
        
        currentSession
            .subscribe(
                onNext: { [unowned self] session in
                    self.auth.session = session
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(SpotifyURLCallbackNotification)
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
            
        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handle(authNotification:)),
//            name: SpotifyURLCallbackNotification,
//            object: nil
//        )
        
        
//        do {
            //try player.start(withClientId: auth.clientID)
            //player.delegate = self
//        } catch let error {
//            print("there was an error starting spotify sdk: \(error.localizedDescription)")
//        }
    }
    
    func performAuthentication() {
            //player.login(withAccessToken: auth.session.accessToken)
        if SPTAuth.supportsApplicationAuthentication() {
            UIApplication.shared.open(auth.spotifyAppAuthenticationURL(), options: [:])
        } else {
            let authenticationScene = Scene.authenticateSpotify(auth.spotifyWebAuthenticationURL())
            sceneCoordinator.transition(to: authenticationScene, type: .modal)
        }
    }
    
    private func handle(callbackURL: URL) {
        if sceneCoordinator.currentViewController is SFSafariViewController {
            sceneCoordinator.pop()
        }

        auth.handleAuthCallback(
            withTriggeredAuthURL: callbackURL,
            callback: { [unowned self] (error, session) in
                if let session = session {
//                    self.auth.renewSession(session, callback: { (error, session) in
//                        os_log("renewed expiration date: %@", log: OSLog.default, type: .info, session?.expirationDate.description ?? "")
//                    })

                    //self.auth.session = session
                    self.currentSession.onNext(session)
                    
                    os_log("access token: %@", log: OSLog.default, type: .info, session.accessToken)
                    os_log("expiration date: %@", log: OSLog.default, type: .info, session.expirationDate.description)
                
                    //self.player.login(withAccessToken: self.auth.session.accessToken)
                } else if let error = error {
                    self.currentSession.onError(error)
                    os_log("spotify auth callback error: %@", log: OSLog.default, type: .error, error.localizedDescription)
                }
            }
        )
    }
    
}

//MARK: - Notification handling
extension DMSpotifyAuthService {
    
    @objc private func handle(authNotification notification: Notification) {
        guard notification.name == SpotifyURLCallbackNotification else {
            fatalError("wrong notification handler")
        }
        
        guard let userInfo = notification.userInfo,
            let url = userInfo[SpotifyURLCallbackNotificationUserInfoURLKey] as? URL else {
            return
        }
    
        handle(callbackURL: url)
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

