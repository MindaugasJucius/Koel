//
//  DMSpotifyPlaybackService.swift
//  Koel
//
//  Created by Mindaugas Jucius on 4/1/18.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift
import AVKit
import MediaPlayer

protocol DMSpotifyPlaybackServiceType {
    
    var authService: DMSpotifyAuthService { get }
    
}

class DMSpotifyPlaybackService: NSObject, DMSpotifyPlaybackServiceType {

    private let disposeBag = DisposeBag()
    
    var authService: DMSpotifyAuthService
    
    private let player: SPTAudioStreamingController = SPTAudioStreamingController.sharedInstance()
    
    private var currentSong: DMEventSong?
    
    let isLoggedIn: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    let isPlaying: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    
    init(authService: DMSpotifyAuthService) {
        self.authService = authService
        super.init()
        player.delegate = self
        player.playbackDelegate = self
        //MPRemoteCommandCenter.shared().playCommand
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
    
    func togglePlayback(forSong song: DMEventSong) -> Observable<Void> {
        return isPlaying.asObserver()
            .take(1)
            .flatMap { [unowned self] playing -> Observable<Void> in
                guard self.currentSong != nil else {
                    return self.play(song: song)
                }
                return self.toggleState(isPlaying: !playing)
            }
            .take(1)
    }
    
    private func play(song: DMEventSong) -> Observable<Void> {
        let playObservable = login()
            .map { _ in }
            .flatMap { [unowned self] _ in
                return Observable<Void>.create { observer in
                    self.player.playSpotifyURI(
                        song.spotifyURI,
                        startingWith: 0,
                        startingWithPosition: 0,
                        callback: { error in
                            guard error == nil else {
                                observer.onError(error!)
                                return
                            }
                            self.currentSong = song
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    )
                    return Disposables.create()
                }
        }
        
        let playingStatus = isPlaying
            .asObservable()
            .skip(1) // skip current value
            .map { _ in }
        
        return Observable
            .zip([playObservable, playingStatus])
            .map { _ in }
    }
    
    private func toggleState(isPlaying playing: Bool) -> Observable<Void> {
        return Observable.create { [unowned self] observer -> Disposable in
            self.player.setIsPlaying(playing) { error in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
}

extension DMSpotifyPlaybackService: SPTAudioStreamingPlaybackDelegate {
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        print("isPlaying \(isPlaying)")
        self.isPlaying.onNext(isPlaying)
        if isPlaying {
            activateAudioSession()
        } else {
            deactivateAudioSession()
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        //print(position)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {
        print("start playing: \(trackUri)")
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        print("stop playing: \(trackUri)")
        currentSong = nil
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChange metadata: SPTPlaybackMetadata!) {
        print(metadata)
    }

}

extension DMSpotifyPlaybackService: SPTAudioStreamingDelegate {

    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        isLoggedIn.onNext(true)
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
    
    // MARK: Activate audio session
    
    func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: Deactivate audio session
    
    func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
