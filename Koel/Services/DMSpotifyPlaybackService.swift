//
//  DMSpotifyPlaybackService.swift
//  Koel
//
//  Created by Mindaugas Jucius on 4/1/18.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import AVKit
import MediaPlayer

protocol DMSpotifyPlaybackServiceType {
    
    var authService: DMSpotifyAuthService { get }
    var songPersistenceService: DMEventSongPersistenceServiceType { get }
    var queuedSongs: Observable<[DMEventSong]> { get }

    var isPlaying: Observable<Bool> { get }
    
    func togglePlayback() -> Observable<Void>
    func nextSong() -> Observable<Void>
    func nextEnabled() -> Observable<Bool>
}

class DMSpotifyPlaybackService: NSObject, DMSpotifyPlaybackServiceType {

    private let disposeBag = DisposeBag()
    
    var authService: DMSpotifyAuthService
    var songPersistenceService: DMEventSongPersistenceServiceType
    var queuedSongs: Observable<[DMEventSong]>
    
    private let player: SPTAudioStreamingController = SPTAudioStreamingController.sharedInstance()
    
    let isLoggedIn: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    private let isPlayingSubject: BehaviorSubject<Bool> = BehaviorSubject(value: false)
        
    var isPlaying: Observable<Bool> {
        return isPlayingSubject.asObservable()
    }
    
    //PROBLEMS
    
    //1. If there's one song and a second one is added, it is not queued
    // maybe move to didStartPlaying
    // add isSpotifyQueued to song
    
    //2. Multiple taps of NEXT doesn't stop playback
    // solution:
        // pause on second tap
        // throttle for 0.3 sec
        // if taps > 1 just ```play(song: DMEventSong) -> Observable<Void>```
    
    
    // case
    // ijungi screena dainu > 1
    // spaudi play, kita daina queueinama
    
    // ijungi screena dainu == 0
    // pridedi, spaudi play daina groja, kitos dainos nera
    
    // ijungi screena dainu == 1,
    // pridedi daina
    // next nieko nedaro
    init(authService: DMSpotifyAuthService,
         songPersistenceService: DMEventSongPersistenceServiceType,
         queuedSongs: Observable<[DMEventSong]>) {
        
        self.authService = authService
        self.queuedSongs = queuedSongs
        self.songPersistenceService = songPersistenceService
        
        super.init()
        player.delegate = self
        player.playbackDelegate = self
        
        try! player.start(withClientId: SPTAuth.defaultInstance().clientID)
        
        secondQueuedSong
            .skipUntil(isPlaying.filter { $0 })
            .flatMap { song -> Observable<DMEventSong> in
                print("init enqueueing next song: \(song.title) \(song.spotifyURI)")
                return self.enqueue(song: song)
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    //MARK: - Queue Helpers

    private lazy var firstQueuedSong: Observable<DMEventSong> = {
        return queuedSongs
            .map { $0.first }
            .filterNil()
    }()
    
    private lazy var secondQueuedSong: Observable<DMEventSong> = {
        return queuedSongs
            .map { songs -> DMEventSong? in
                return songs[safe: 1]
            }
            .filterNil()
            .filter { $0.state == .queued }
    }()
    
    //MARK: - Public
    
    func togglePlayback() -> Observable<Void> {
        return Observable.zip(isPlaying, firstQueuedSong)
            .flatMap { [unowned self] (playing, song) -> Observable<Void> in
                guard song.state == .upNext else {
                    return self.play(song: song)
                }
                return self.togglePlaybackState(isPlaying: !playing)
            }
            .take(1)
    }
    
    func nextSong() -> Observable<Void> {
        return Observable.create { [unowned self] observer -> Disposable in
            self.player.skipNext(self.sptObservableCallback(withObserver: observer))
            return Disposables.create()
        }
    }
    
    func nextEnabled() -> Observable<Bool> {
        return Observable.combineLatest(queuedSongs.map { $0.count > 1 }, isPlaying.filter { $0 })
            .map { $0 && $1 }
    }
    
    //MARK: - Private
    
    private func login() -> Observable<Bool> {
        return authService.currentSessionObservable.map { session -> String in
                return session.accessToken
            }
            .do(onNext: { [unowned self] accessToken in
                self.player.login(withAccessToken: accessToken)
            })
            .flatMap { [unowned self] _ in
                return self.isLoggedIn.asObservable().filter { $0 }
            }
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
                        callback: self.sptObservableCallback(withObserver: observer)
                    )
                    return Disposables.create()
                }
            }
            .flatMap { [unowned self] in
                return self.songPersistenceService.update(song: song, toState: .queued)
            }
            .map { _ in }
        
        let playingStatus = isPlaying
            .asObservable()
            .skip(1) // skip current value
            .map { _ in }
        
        return Observable
            .zip([playObservable, playingStatus])
            .map { _ in }
    }
    
    private func togglePlaybackState(isPlaying playing: Bool) -> Observable<Void> {
        return Observable.create { [unowned self] observer -> Disposable in
            self.player.setIsPlaying(playing, callback: self.sptObservableCallback(withObserver: observer))
            return Disposables.create()
        }
    }
    
    private func enqueue(song: DMEventSong) -> Observable<DMEventSong> {
        return Observable.create { [unowned self] observer -> Disposable in
            self.player.queueSpotifyURI(song.spotifyURI, callback: { error in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }
                observer.onNext(song)
                observer.onCompleted()
            })
                return Disposables.create()
            }
            .flatMap { [unowned self] song in
                return self.songPersistenceService.update(song: song, toState: .queued)
            }
    }
    
    private func sptObservableCallback(withObserver observer: AnyObserver<Void>) -> SPTErrorableOperationCallback {
        return { error in
            guard error == nil else {
                print(error?.localizedDescription)
                observer.onError(error!)
                return
            }
            observer.onNext(())
            observer.onCompleted()
        }
    }
    
}

extension DMSpotifyPlaybackService: SPTAudioStreamingPlaybackDelegate {
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        print("isPlaying \(isPlaying)")
        self.isPlayingSubject.onNext(isPlaying)
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
//        secondQueuedSong
//            .flatMap { song -> Observable<DMEventSong> in
//                print("enqueueing next song: \(song.title) \(song.spotifyURI)")
//                return self.enqueue(song: song)
//            }
//            .subscribe()
//            .dispose()
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        print("stop playing: \(trackUri)")
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChange metadata: SPTPlaybackMetadata!) {
        print("metadata")
        print("current track: \(metadata.currentTrack?.name)")
        print("next track: \(metadata.nextTrack?.name)")
    }
    
    func audioStreamingDidPopQueue(_ audioStreaming: SPTAudioStreamingController!) {
        print("pop queue")
    }
    
    func audioStreamingDidSkip(toNextTrack audioStreaming: SPTAudioStreamingController!) {
        print("did skip to next")
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
