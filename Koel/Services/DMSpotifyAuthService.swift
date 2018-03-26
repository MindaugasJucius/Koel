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

private let KoelSpotifySessionUserDefaultsKey = "koel_spotify_session"

let SpotifyURLCallbackNotification = Notification.Name("SpotifyURLCallbackNotification")
let SpotifyURLCallbackNotificationUserInfoURLKey = "SpotifyURLCallbackNotificationUserInfoURLKey"

class DMSpotifyAuthService: NSObject {

    let sceneCoordinator: SceneCoordinatorType
    
    private let auth: SPTAuth = SPTAuth.defaultInstance()
    //private let player: SPTAudioStreamingController = SPTAudioStreamingController.sharedInstance()
    
    var authenticationIsNeeded: Bool {
        return auth.session == nil || !auth.session.isValid()
    }
    
    var currentSession: SPTSession? {
        return auth.session
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthNotification(notification:)),
            name: SpotifyURLCallbackNotification,
            object: nil
        )
        
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

                    self.auth.session = session
                    
                    os_log("access token: %@", log: OSLog.default, type: .info, session.accessToken)
                    os_log("expiration date: %@", log: OSLog.default, type: .info, session.expirationDate.description)
                
                    //self.player.login(withAccessToken: self.auth.session.accessToken)
                } else if let error = error {
                    os_log("spotify auth callback error: %@", log: OSLog.default, type: .error, error.localizedDescription)
                }
            }
        )
    }
    
}

//MARK: - Notification handling
extension DMSpotifyAuthService {
    
    @objc private func handleAuthNotification(notification: Notification) {
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

