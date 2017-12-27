//
//  DMSpotifyService.swift
//  Koel
//
//  Created by Mindaugas Jucius on 27/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import SafariServices

private let KoelSpotifySessionUserDefaultsKey = "koel_spotify_session"

class DMSpotifyService: NSObject {

    let sceneCoordinator: SceneCoordinatorType
    
    private let auth: SPTAuth! = SPTAuth.defaultInstance()
    private let player: SPTAudioStreamingController! = SPTAudioStreamingController.sharedInstance()
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
        super.init()
        auth.clientID = "e693a6d7103f4d46ac64eebc6906f8f4"
        auth.sessionUserDefaultsKey = KoelSpotifySessionUserDefaultsKey
        auth.redirectURL = URL(string: "Koel://returnAfterLogin")
        auth.requestedScopes = [
            SPTAuthStreamingScope,
            SPTAuthUserReadTopScope,
            SPTAuthUserLibraryReadScope,
            SPTAuthPlaylistReadPrivateScope
        ]
        
        do {
            try player.start(withClientId: auth.clientID)
            player.delegate = self
        } catch let error {
            print("there was an error starting spotify sdk: \(error.localizedDescription)")
        }
    }
    
    func performLoginIfNeeded() {
        if auth.session != nil && auth.session.isValid() {
            player.login(withAccessToken: auth.session.accessToken)
        } else {
            if SPTAuth.supportsApplicationAuthentication() {
                UIApplication.shared.open(auth.spotifyAppAuthenticationURL(), options: [:])
            } else {
                let authenticationScene = Scene.authenticateSpotify(auth.spotifyWebAuthenticationURL())
                sceneCoordinator.transition(to: authenticationScene, type: .modal)
            }
        }
    }
    
    func handle(callbackURL: URL) {
        if sceneCoordinator.currentViewController is SFSafariViewController {
            sceneCoordinator.pop()
        }
        
        auth.handleAuthCallback(
            withTriggeredAuthURL: callbackURL,
            callback: { [unowned self] (error, session) in
                if session != nil {
                    self.player.login(withAccessToken: self.auth.session.accessToken)
                }
            }
        )
    }
    
}

extension DMSpotifyService: SPTAudioStreamingPlaybackDelegate {
    
}

extension DMSpotifyService: SPTAudioStreamingDelegate {
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        player.playSpotifyURI("spotify:track:58s6EuEYJdlb0kO7awm3Vp", startingWith: 0, startingWithPosition: 0) { error in
            guard let error = error else {
                return
            }
            print("audio playing failed due to an error: \(error.localizedDescription)")
        }
    }
}
