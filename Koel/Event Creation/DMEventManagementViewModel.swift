//
//  DMEventManagementController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 06/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Action
import RxSwift
import RealmSwift
import MultipeerConnectivity
import RxDataSources

protocol DMEventManagementViewModelType: DMEventSongsRepresentable, DMEventParticipantSongsEditable {
    
    init(multipeerService: DMEventMultipeerService,
         reachabilityService: ReachabilityService,
         promptCoordinator: PromptCoordinating,
         songsRepresenter: DMEventSongsRepresentable & DMEventSongsManagerSeparatable,
         songsEditor: DMEventParticipantSongsEditable & DMEventHostSongsEditable)

    var onSongsDelete: CocoaAction { get }
    var onUpvote: (DMEventSong) -> CocoaAction { get }
    var skipSongForward: Observable<Void> { get }
    
    var playbackEnabled: Observable<Bool> { get }
    var isPlaying: Observable<Bool> { get }
    
    var onNext: CocoaAction { get }
    var onPlay: CocoaAction { get }
    
}

class DMEventManagementViewModel: DMEventManagementViewModelType, MultipeerViewModelType, BackgroundDisconnectType {

    private let disposeBag = DisposeBag()
    private let sptPlaybackService: DMSpotifyPlaybackServiceType

    private let songsRepresenter: DMEventSongsManagerSeparatable & DMEventSongsRepresentable
    private let songsEditor: DMEventHostSongsEditable & DMEventParticipantSongsEditable
    
    let songsSectioned: Observable<[SongSection]>
    
    let onSongsDelete: CocoaAction
    let onUpvote: (DMEventSong) -> CocoaAction
    let skipSongForward: Observable<Void>
    
    let promptCoordinator: PromptCoordinating
    let multipeerService: DMEventMultipeerService

    var backgroundTaskID = UIBackgroundTaskInvalid

    required init(multipeerService: DMEventMultipeerService,
                  reachabilityService: ReachabilityService,
                  promptCoordinator: PromptCoordinating,
                  songsRepresenter: DMEventSongsManagerSeparatable & DMEventSongsRepresentable,
                  songsEditor: DMEventHostSongsEditable & DMEventParticipantSongsEditable) {
        
        self.multipeerService = multipeerService
        self.songsRepresenter = songsRepresenter
        self.songsEditor = songsEditor
        self.promptCoordinator = promptCoordinator
        
        let sptAuthService = DMSpotifyAuthService(promptCoordinator: promptCoordinator)
        
        self.sptPlaybackService = DMSpotifyPlaybackService(authService: sptAuthService,
                                                           reachabilityService: reachabilityService,
                                                           skipSongForward: songsEditor.skipSongForward,
                                                           updateSongToState: songsEditor.updateSongToState,
                                                           addedSongs: songsRepresenter.addedSongs,
                                                           playingSong: songsRepresenter.playingSong)
        
        self.onSongsDelete = songsEditor.onSongsDelete
        self.onUpvote = songsEditor.onUpvote
        self.skipSongForward = songsEditor.skipSongForward
        
        self.songsSectioned = songsRepresenter.songsSectioned
        
        multipeerService.startBrowsing()
        multipeerService.startAdvertising()
        
        NotificationCenter.default.addObserver(
            forName: Notifications.didEnterBackground,
            object: nil,
            queue: nil,
            using: didEnterBackgroundNotificationHandler
        )
        
        NotificationCenter.default.addObserver(
            forName: Notifications.willEnterForeground,
            object: nil,
            queue: nil,
            using: willEnterForegroundNotificationHandler
        )
        
        setupConnectionObservables()
    }
    
    // MARK: - Connection observables
    
    // MARK: shared
    private var connectionRequests: Observable<(DMEventPeer, (Bool) -> (), Bool)> {
        return multipeerService
            .incomingPeerInvitations()
            .map { (client, context, handler) in
                
                guard let contextDictionary = context else {
                    return (DMEventPeer.peer(withPeerID: client, context: nil), handler, false)
                }
                
                let reconnectKey = ContextKeys.reconnect.rawValue
                let isReconnect = contextDictionary[reconnectKey] != nil
                let eventPeer = DMEventPeer.peer(
                    withPeerID: client,
                    context: contextDictionary as? [String : String]
                )
                
                return (eventPeer, handler, isReconnect)
            }
            .share()
    }
    
    private var participantWantsJoinRequests: Observable<(DMEventPeer, (Bool) -> ())> {
        return connectionRequests
            .filter{ (_, _, reconnect) in
                return !reconnect
            }
            .map { (client, handler, _) in
                return (client, handler)
        }
    }
    
    private var participantWantsReconnectRequests: Observable<(Bool) -> ()> {
        return connectionRequests
            .filter{ (_, _, reconnect) in
                return reconnect
            }
            .map { (_, handler, _) in
                return handler
        }
    }
    
    private func setupConnectionObservables() {
        participantWantsJoinRequests
            .flatMap { (peer, invitationHandler) -> Observable<String> in
                return self.promptCoordinator.promptFor("\(String(describing: peer.peerID?.displayName)) wants to join your party",
                    cancelAction: "Deny",
                    actions: ["Accept"])
                    .do(onNext: { action in
                        let hasAccepted = action == "Accept"
                        invitationHandler(hasAccepted)
                    })
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        participantWantsReconnectRequests
            .subscribe(onNext: { handler in
                handler(true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Playback bindables
    
    lazy var onNext: CocoaAction = {
        self.sptPlaybackService.onNext
    }()
    
    lazy var onPlay: CocoaAction = {
        return CocoaAction { [unowned self] in
            return self.sptPlaybackService.togglePlayback.catchError { error in
                return self.promptCoordinator.promptFor(error.localizedDescription, cancelAction: "cancel", actions: nil)
                    .map { _ in }
                    .take(1)
            }
        }
    }()
    
    lazy var playbackEnabled: Observable<Bool> = {
        let queuedSongsAvailable = songsRepresenter
            .addedSongs
            .map { !$0.isEmpty }
        
        let playingSongAvailable = songsRepresenter
            .playingSong
            .map { $0 != nil }
        
        return Observable.combineLatest(queuedSongsAvailable, playingSongAvailable) { $0 || $1 }
    }()
    
    lazy var isPlaying: Observable<Bool> = {
        return sptPlaybackService.isPlaying
    }()
    
}

