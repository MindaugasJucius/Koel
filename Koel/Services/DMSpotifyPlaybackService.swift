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

    var isPlaying: Observable<Bool> { get }
    
    var togglePlayback: Observable<Void> { get }
    func nextSong() -> Observable<Void>
    func nextEnabled() -> Observable<Bool>
}

class DMSpotifyPlaybackService: NSObject, DMSpotifyPlaybackServiceType {

    private let disposeBag = DisposeBag()
    
    var authService: DMSpotifyAuthService
    var songPersistenceService: DMEventSongPersistenceServiceType
    
    var addedSongs: Observable<[DMEventSong]>
    var playingSong: Observable<DMEventSong?>
    var upNextSong: Observable<DMEventSong?>
    
    private let player: SPTAudioStreamingController = SPTAudioStreamingController.sharedInstance()
    
    let isLoggedIn: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    private let isPlayingSubject: BehaviorSubject<Bool> = BehaviorSubject(value: false)
        
    var isPlaying: Observable<Bool> {
        return isPlayingSubject.asObservable()
    }
    
    private let metadataCurrentURISubject: BehaviorSubject<String?> = BehaviorSubject(value: .none)

    private var metadataMatchesPlayingTrackURI: Observable<Bool> {
        let currentURI = metadataCurrentURISubject
            .asObservable()
            .filterNil()
        
        return Observable.combineLatest(currentURI, playingSong.filterNil()) { (currentURI, playing) -> Bool in
            return currentURI == playing.spotifyURI
        }
        .distinctUntilChanged()
    }
    
    init(authService: DMSpotifyAuthService,
         songPersistenceService: DMEventSongPersistenceServiceType,
         addedSongs: Observable<[DMEventSong]>,
         playingSong: Observable<DMEventSong?>,
         upNextSong: Observable<DMEventSong?>) {
        
        self.authService = authService
        self.songPersistenceService = songPersistenceService
        
        self.addedSongs = addedSongs
        self.playingSong = playingSong
        self.upNextSong = upNextSong
        
        super.init()
        player.delegate = self
        player.playbackDelegate = self
        
        try! player.start(withClientId: SPTAuth.defaultInstance().clientID)
        
        let distinctFirstAddedSong = addedSongs
            .map { $0.first }
            .filterNil()
            .distinctUntilChanged()
            .skip(1) // initial added song is played by calling `playSpotifyURI`

        // there's no case when both of zipped observables
        // are fired for the same index and
        // upNextSong is not nil, thus
        // skipUntil { upNextSong.filter { $0 == nil }) } is not needed
        
        // Start playback flow:
        // 1. `distinctFirstAddedSong` fires only after initial song has had
        //    `playSpotifyURI` called on it and its state has been changed to `.playing`.
        // 2. These observables are zipped, thus `distinctFirstAddedSong` waits
        //    for `metadataMatchesPlayingTrackURI` to fire for current
        //    index. It only does when `metadata.currentTrack.uri` == `playingSong.spotifyURI`.
        // 3. `distinctFirstAddedSong` becomes `.queued`.
        
        // Song skipping flow:
        // 1. On next tap, the queued song becomes `.playing`, and `distinctFirstAddedSong`
        //    fires with a new value.
        // 2. It waits for `metadata.currentTrack.uri` to match the now `.playing` song's uri.
        // 3. `distinctFirstAddedSong` becomes `.queued`.
        Observable.zip(distinctFirstAddedSong, metadataMatchesPlayingTrackURI.filter { $0 })
            .map { $0.0 }
            .flatMap { [unowned self] distinctFirstAddedSong in
                return self.enqueue(song: distinctFirstAddedSong)
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    //MARK: - Public
    
    lazy var togglePlayback: Observable<Void> = {
        return Observable
            .combineLatest(playingSong, addedSongs, isPlaying)
            .take(1)
            .flatMap { (playingSong, addedSongs, playing) -> Observable<Void> in
                if let firstAdded = addedSongs.first, playingSong == nil {
                    return self.play(song: firstAdded)
                }
                
                if let _ = playingSong {
                    return self.togglePlaybackState(isPlaying: !playing)
                }
                
                return Observable.just(())
            }
            .take(1)
    }()
    
    func nextSong() -> Observable<Void> {
        return Observable.create { [unowned self] observer -> Disposable in
            self.player.skipNext(self.sptObservableCallback(withObserver: observer))
            return Disposables.create()
        }
    }
    
    func nextEnabled() -> Observable<Bool> {
        return Observable.combineLatest(upNextSong.map { $0 != nil }, isPlaying.filter { $0 })
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
            .flatMap { [unowned self] in
                return self.songPersistenceService.update(song: song, toState: .playing)
            }
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
            .map { _ in }
        
        let playingStatus = isPlaying
            .asObservable()
            .skip(1) // skip default value
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
                        print(error?.localizedDescription)
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
        isPlayingSubject.onNext(isPlaying)
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
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChange metadata: SPTPlaybackMetadata!) {
        print("metadata")
        print("current track: \(metadata.currentTrack?.name)")
        print("next track: \(metadata.nextTrack?.name)")

        metadataCurrentURISubject.onNext(metadata.currentTrack?.uri)
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
