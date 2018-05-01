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

class DMEventManagementViewModel: ViewModelType, MultipeerViewModelType, BackgroundDisconnectType, SongSharingViewModelType {
    
    var songSharingViewModel: DMEventSongSharingViewModelType
    
    private let disposeBag = DisposeBag()
    private let sptPlaybackService: DMSpotifyPlaybackServiceType

    let sceneCoordinator: SceneCoordinatorType

    var backgroundTaskID = UIBackgroundTaskInvalid

    var multipeerService: DMEventMultipeerService {
        return songSharingViewModel.multipeerService
    }
    
    init(sceneCoordinator: SceneCoordinatorType,
         songSharingViewModel: DMEventSongSharingViewModelType) {
        
        self.sceneCoordinator = sceneCoordinator
        self.songSharingViewModel = songSharingViewModel
        
        let sptAuthService = DMSpotifyAuthService(sceneCoordinator: sceneCoordinator)

        self.sptPlaybackService = DMSpotifyPlaybackService(authService: sptAuthService,
                                                           songPersistenceService: songSharingViewModel.songPersistenceService,
                                                           addedSongs: songSharingViewModel.addedSongs,
                                                           playingSong: songSharingViewModel.playingSong,
                                                           upNextSong: songSharingViewModel.upNextSong)

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
            .subscribe(onNext: { [unowned self] invitation in
                let alert = UIAlertController(title: "Connection request", message: "\(invitation.0.peerID?.displayName) wants to join your party", preferredStyle: .alert)
                let connectAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
                    let invitationHandler = invitation.1
                    invitationHandler(true)
                })
                alert.addAction(connectAction)
                self.sceneCoordinator.currentViewController.present(
                    alert,
                    animated: true,
                    completion: nil
                )
            })
            .disposed(by: disposeBag)
        
        participantWantsReconnectRequests
            .subscribe(onNext: { handler in
                handler(true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Playback bindables
    
    lazy var onNext: CocoaAction = {
        return Action(
            enabledIf: sptPlaybackService.nextEnabled(),
            workFactory: { [unowned self] in
                return self.sptPlaybackService.nextSong()
                    .flatMap {
                        return self.songSharingViewModel.addedSongs
                                .map { $0.first }
                                .filterNil()
                    }
                    .flatMap { song in
                        return self.songSharingViewModel.onPlayed.execute(song)
                    }
            }
        )

    }()
    
    lazy var onPrevious: CocoaAction = {
        return Action(enabledIf: songSharingViewModel.playedSongs.map { $0.first != nil }, workFactory: { [unowned self] in
            return .just(())
        })
    }()
    
    lazy var onPlay: CocoaAction = {
        return CocoaAction { [unowned self] in
            return self.sptPlaybackService.togglePlayback
        }
    }()
    
    lazy var isPlaying: Observable<Bool> = {
        return sptPlaybackService.isPlaying
    }()
    
    // MARK: - Connection bindables
    
    private func onInvitesClose() -> CocoaAction {
        return CocoaAction {
            return self.sceneCoordinator.pop(animated: true)
        }
    }
    
    func onInvite() -> CocoaAction {
        return CocoaAction { [unowned self] _ in
            
            let invitationsViewModel = DMEventInvitationsViewModel(
                withSceneCoordinator: self.sceneCoordinator,
                multipeerService: self.multipeerService,
                onClose: self.onInvitesClose()
            )
            
            return self.sceneCoordinator.transition(
                to: Scene.invite(invitationsViewModel),
                type: .modal
            )
        }
    }
    
}
