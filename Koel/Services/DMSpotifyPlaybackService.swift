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

    var isPlaying: Observable<Bool> { get }
    
    var togglePlayback: Observable<Void> { get }
    
    func nextSong() -> Observable<Void>
    func nextEnabled() -> Observable<Bool>
}


class DMSpotifyPlaybackService: NSObject, DMSpotifyPlaybackServiceType {

    private let disposeBag = DisposeBag()
    
    var authService: DMSpotifyAuthService
    
    var addedSongs: Observable<[DMEventSong]>
    var playingSong: Observable<DMEventSong?>
    var upNextSong: Observable<DMEventSong?>

    var updateSongToState: (DMEventSong, DMEventSongState) -> (Observable<Void>)
    
    private let player: SPTAudioStreamingController = SPTAudioStreamingController.sharedInstance()
    
    private let isLoggedIn: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    private let isPlayingSubject: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    private let playingURISubject: BehaviorSubject<String?> = BehaviorSubject(value: .none)
    private let metadataCurrentURISubject: BehaviorSubject<String?> = BehaviorSubject(value: .none)
    
    private let reachabilityService: DefaultReachabilityService = try! DefaultReachabilityService()
    
    private var playingURI: Observable<String?> {
        return playingURISubject.asObservable()
    }
    
    var isPlaying: Observable<Bool> {
        return isPlayingSubject.asObservable()
    }
    
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
         updateSongToState: @escaping (DMEventSong, DMEventSongState) -> (Observable<Void>),
         addedSongs: Observable<[DMEventSong]>,
         playingSong: Observable<DMEventSong?>,
         upNextSong: Observable<DMEventSong?>) {
        
        self.authService = authService
        self.updateSongToState = updateSongToState
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
            .skip(1)
        
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
            .flatMap { [unowned self] songToEnqueue in
                return self.enqueue(song: songToEnqueue)
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    //MARK: - Public
    
    lazy var togglePlayback: Observable<Void> = {
        return Observable
            .combineLatest(playingSong, addedSongs, isPlaying, playingURI)
            .take(1) // addedSongs changes on toggling, causing combineLatest to fire multiple times
            .flatMap { (playingSong, addedSongs, isPlaying, playingURI) -> Observable<Void> in
                if let firstAdded = addedSongs.first, playingSong == nil {
                    return self.play(song: firstAdded)
                }
                
                if let playingSong = playingSong {
                    if playingURI == nil { // playback hasn't been started yet
                        return self.play(song: playingSong)
                    }
                    return self.togglePlaybackState(isPlaying: !isPlaying)
                }

                return .just(())
            }
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
        return reachabilityService.reachability
            .flatMap { [unowned self] status -> Observable<SPTSession> in
                if status.reachable {
                    return self.authService.currentSessionObservable
                } else {
                    return .error(ReachabilityStatusError.networkUnavailable)
                }
            }
            .map { $0.accessToken }
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
                return self.updateSongToState(song, .playing)
            }
        
        let playingStatus = isPlaying
            .asObservable()
            .skip(1) // skip default value
        
        return Observable
            .zip(playObservable, playingStatus)
            .map { _ in }
            .take(1)
    }
    
    private func togglePlaybackState(isPlaying playing: Bool) -> Observable<Void> {
        return Observable.create { [unowned self] observer -> Disposable in
            self.player.setIsPlaying(playing, callback: self.sptObservableCallback(withObserver: observer))
            return Disposables.create()
        }
    }
    
    private func enqueue(song: DMEventSong) -> Observable<Void> {
        return Observable.create { [unowned self] observer -> Disposable in
            self.player.queueSpotifyURI(song.spotifyURI, callback: self.sptObservableCallback(withObserver: observer))
            return Disposables.create()
        }
        .flatMap { [unowned self] in
            return self.updateSongToState(song, .queued)
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
        playingURISubject.onNext(trackUri)
        print("start playing: \(trackUri)")
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        playingURISubject.onNext(nil)
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
