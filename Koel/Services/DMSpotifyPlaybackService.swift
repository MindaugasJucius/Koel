//
//  DMSpotifyPlaybackService.swift
//  Koel
//
//  Created by Mindaugas Jucius on 4/1/18.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift

protocol DMSpotifyPlaybackServiceType {
    
    var authService: DMSpotifyAuthService { get }
    
}

class DMSpotifyPlaybackService: NSObject, DMSpotifyPlaybackServiceType {

    private let disposeBag = DisposeBag()
    
    var authService: DMSpotifyAuthService
    
    private let player: SPTAudioStreamingController = SPTAudioStreamingController.sharedInstance()
    
    let isLoggedIn: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    let isPlaying: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    
    init(authService: DMSpotifyAuthService) {
        self.authService = authService
        super.init()
        player.delegate = self
        try! player.start(withClientId: SPTAuth.defaultInstance().clientID)
    }
    
    private func login() -> Observable<Bool> {
        return authService.currentSessionObservable.map { session -> String in
            return session.accessToken
            }
            .do(onNext: { [unowned self] accessToken in
                self.player.login(withAccessToken: accessToken)
            })
            .flatMap { [unowned self] _ in
                return self.isLoggedIn.asObservable().filter {
                    $0
                }
        }
    }
    
    func play(song: DMEventSong) -> Observable<Void> {
        return login()
        .map { _ in }
        .do(onNext: { [unowned self] in
            self.player.playSpotifyURI(song.spotifyURI, startingWith: 0, startingWithPosition: 0, callback: { (error) in
                        print(error)
                    }
                )
            }
        )
    }
    
}

extension DMSpotifyPlaybackService: SPTAudioStreamingPlaybackDelegate {

    
    
}

extension DMSpotifyPlaybackService: SPTAudioStreamingDelegate {

    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        isLoggedIn.onNext(true)
//        player.playSpotifyURI("spotify:track:58s6EuEYJdlb0kO7awm3Vp", startingWith: 0, startingWithPosition: 0) { error in
//            guard let error = error else {
//                return
//            }
//            print("audio playing failed due to an error: \(error.localizedDescription)")
//        }
    }
    
    func audioStreamingDidLogout(_ audioStreaming: SPTAudioStreamingController!) {
        isLoggedIn.onNext(false)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveMessage message: String!) {
        print(message)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        print(error)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        self.isPlaying.onNext(isPlaying)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {
        print(trackUri)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        print(trackUri)
    }
}
