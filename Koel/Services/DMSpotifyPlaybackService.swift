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

enum PlaybackError: Error {
    case needToLoginToPlaySongs
}

protocol DMSpotifyPlaybackServiceType {
    
    var isPlaying: Observable<Bool> { get }
    var togglePlayback: Observable<Void> { get }
    var onNext: CocoaAction { get }
    var trackPlaybackPercentCompleted: Observable<Double> { get }

}


class DMSpotifyPlaybackService: NSObject, DMSpotifyPlaybackServiceType {

    private let disposeBag = DisposeBag()
    
    let authService: DMSpotifyAuthService
    
    let addedSongs: Observable<[DMEventSong]>
    let playingSong: Observable<DMEventSong?>

    let updateSongToState: (DMEventSong, DMEventSongState) -> (Observable<Void>)
    let skipSongForward: Observable<Void>
    
    private let player: SPTAudioStreamingController = SPTAudioStreamingController.sharedInstance()
    
    private let isLoggedIn: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    private let isPlaybackActiveSubject: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    private let isTrackPlayingSubject: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    private let trackPositionSubject: PublishSubject<TimeInterval> = PublishSubject()

    private let reachabilityService: ReachabilityService
    
    init(authService: DMSpotifyAuthService,
         reachabilityService: ReachabilityService,
         skipSongForward: Observable<Void>,
         updateSongToState: @escaping (DMEventSong, DMEventSongState) -> (Observable<Void>),
         addedSongs: Observable<[DMEventSong]>,
         playingSong: Observable<DMEventSong?>) {
        
        self.authService = authService
        self.reachabilityService = reachabilityService
        self.skipSongForward = skipSongForward
        self.updateSongToState = updateSongToState
        self.addedSongs = addedSongs
        self.playingSong = playingSong
        
        super.init()
        player.delegate = self
        player.playbackDelegate = self
        
        try! player.start(withClientId: SPTAuth.defaultInstance().clientID)
        
        // Update persisted DMEventSong state on track end
        
        let isTrackEnding = trackPlaybackPercentCompleted
            .map { $0 >= 0.995 }
        
        isTrackPlayingSubject.asObservable().filter { !$0 }
            .skip(1) // nil when track playback has ended
            .withLatestFrom(isTrackEnding) // in case if track playback ended due to an error, prevent state edit
            .filter { $0 }
            .flatMap { _ in
                return self.nextSong()
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    //MARK: - Public
    
    lazy var isPlaying: Observable<Bool> = {
        return isPlaybackActiveSubject.asObservable()
    }()
    
    lazy var trackPlaybackPercentCompleted: Observable<Double> = {
        return trackPositionSubject.asObservable()
            .withLatestFrom(playingSong.filterNil()) { (trackPosition, playingSong) -> Double in
                let durationInSeconds = playingSong.durationSeconds
                return trackPosition / durationInSeconds
            }
    }()
    
    lazy var togglePlayback: Observable<Void> = {
        return Observable.combineLatest(playingSong, addedSongs, isPlaying)
            .take(1) // addedSongs changes on toggling, causing combineLatest to fire repeatedly
            .flatMap { (playingSong, addedSongs, isPlaying) -> Observable<Void> in
                if let firstAdded = addedSongs.first, playingSong == nil {
                    return self.play(song: firstAdded)
                }
                
                if let _ = playingSong {
                    return self.togglePlaybackState(isPlaying: !isPlaying)
                }

                return .just(())
            }
    }()
    
    lazy var onNext: CocoaAction = {
        return Action(
            enabledIf: nextEnabled(),
            workFactory: { [unowned self] in
                return self.nextSong()
            }
        )
    }()
    
    //MARK: - Private
    
    private func nextSong() -> Observable<Void> {
        return self.skipSongForward
            .flatMap { self.addedSongs }
            .map { $0.first }
            .take(1)
            .filterNil()
            .flatMap { self.play(song: $0) }
    }
    
    private func nextEnabled() -> Observable<Bool> {
        return addedSongs.map { !$0.isEmpty }
    }
    
    private func login() -> Observable<Bool> {
        let performAndWaitForLogin = reachabilityService.reachability
            .flatMap { [unowned self] status -> Observable<SPTSession> in
                if status.reachable {
                    let sptAction = UIConstants.strings.SPTActionPlayback
                    return self.authService.spotifySession(forAction: sptAction)
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
            .take(1)
        
        return isLoggedIn.asObservable()
            .flatMap { loggedIn -> Observable<Bool> in
                if loggedIn {
                    return .just(loggedIn)
                }
                return performAndWaitForLogin
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
                        startingWithPosition: song.durationSeconds - 10,
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
    
    private func sptObservableCallback(withObserver observer: AnyObserver<Void>) -> SPTErrorableOperationCallback {
        return { error in
            guard error == nil else {
                print("sptObservableCallback \(error)")
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
        isPlaybackActiveSubject.onNext(isPlaying)
        if isPlaying {
            activateAudioSession()
        } else {
            deactivateAudioSession()
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        trackPositionSubject.onNext(position)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {
        print("start playing: \(trackUri)")
        isTrackPlayingSubject.onNext(true)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        print("stop playing: \(trackUri)")
        isTrackPlayingSubject.onNext(false)
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
