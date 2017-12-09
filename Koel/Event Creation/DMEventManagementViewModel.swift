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

class DMEventManagementViewModel: ViewModelType, BackgroundDisconnectType {
    
    private let disposeBag = DisposeBag()
    
    private let peers = BehaviorSubject<[EventPeerSection]>(value: [EventPeerSection(model: "", items: [])])
    
    let sceneCoordinator: SceneCoordinatorType
    let songPersistenceService: DMEventSongPersistenceServiceType
    let multipeerService: DMEventMultipeerService

    var backgroundTaskID = UIBackgroundTaskInvalid
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType, songPersistenceService: DMEventSongPersistenceServiceType) {
        
        self.sceneCoordinator = sceneCoordinator
        self.songPersistenceService = songPersistenceService
        
        self.multipeerService = DMEventMultipeerService(
            withDisplayName: UIDevice.current.name,
            asEventHost: true
        )
        
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
        setupSongPersistenceObservables()
    }
    
    // MARK: - Connection observables
    
    private var incommingInvitations: Observable<(DMEventPeer, (Bool) -> (), Bool)> {
        return multipeerService
            .incomingPeerInvitations()
            .map { (client, context, handler) in
                
                guard let contextDictionary = context else {
                    return (DMEventPeer.init(withContext: nil, peerID: client), handler, false)
                }
                
                let isReconnect = contextDictionary[MultipeerEventContexts.ContextKeys.reconnect.rawValue] != nil
                let eventPeer = DMEventPeer.init(withContext: contextDictionary as? [String : String], peerID: client)
                
                return (eventPeer, handler, isReconnect)
            }
            .share()
    }
    
    private var allPeersSectioned: Observable<[EventPeerSection]> {
        return Observable
            .of(multipeerService.nearbyFoundPeers(),
                multipeerService.connectedPeers())
            .merge()
            .map { results in
                
                let peersWithoutHosts = results.filter { !$0.isHost }
                
                let connectedPeers = peersWithoutHosts.filter { $0.isConnected }
                let nearbyPeers = peersWithoutHosts.filter { !$0.isConnected }
                
                print("CONNECTION OBSERVABLES RESULTS:")
                print(results.map { return "\($0.peerDeviceDisplayName) \($0.isConnected)" })
                
                return [
                    EventPeerSection(model: "Joined", items: connectedPeers),
                    EventPeerSection(model: "Nearby", items: nearbyPeers)
                ]
            }
            .observeOn(MainScheduler.instance)
    }
    
    private var incommingParticipantInvitations: Observable<(DMEventPeer, (Bool) -> ())> {
        return incommingInvitations
            .filter{ (_, _, reconnect) in
                return !reconnect
            }
            .map { (client, handler, _) in
                return (client, handler)
        }
    }
    
    private var incommingParticipantReconnectInvitations: Observable<(Bool) -> ()> {
        return incommingInvitations
            .filter{ (_, _, reconnect) in
                return reconnect
            }
            .map { (_, handler, _) in
                return handler
        }
    }
    
    private func setupConnectionObservables() {
        incommingParticipantInvitations
            .subscribe(onNext: { [unowned self] invitation in
                let alert = UIAlertController(title: "Connection request", message: "\(invitation.0.peerDeviceDisplayName) wants to join your party", preferredStyle: .alert)
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
        
        allPeersSectioned
            .subscribe(peers.asObserver())
            .disposed(by: disposeBag)
        
        incommingParticipantReconnectInvitations
            .subscribe(onNext: { handler in
                handler(true)
            })
            .disposed(by: disposeBag)
        
        onSongCreate.errors.subscribe(
            onNext: { actionError in
                print("actionError \(actionError.localizedDescription)")
            }
        ).disposed(by: disposeBag)
    }
    
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
                peers: self.peers,
                onClose: self.onInvitesClose()
            )
            
            return self.sceneCoordinator.transition(
                to: Scene.invite(invitationsViewModel),
                type: .modal
            )
        }
    }
    
    // MARK: - Song persistence observables
    
    var songsSectioned: Observable<[SongSection]> {
        return songPersistenceService.songs()
            .map { results in
                
                let songSortDescriptors = [
                    SortDescriptor(keyPath: "upvoteCount", ascending: false),
                    SortDescriptor(keyPath: "added", ascending: true)
                ]
                
                let queuedSongs = results
                    .filter("played == nil")
                    .sorted(by: songSortDescriptors)
                
                let playedSongs = results
                    .filter("played != nil")
                    .sorted(byKeyPath: "played", ascending: false)
                
                return [
                    SongSection(model: "queued", items: queuedSongs.toArray()),
                    SongSection(model: "played", items: playedSongs.toArray())
                ]
            }
            .observeOn(MainScheduler.instance)
    }
    
    private func setupSongPersistenceObservables() {
        songPersistenceService.songs()
            .do(onNext: { results in
                    print("persisted songs count\(results.count)")
                }
            )
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    // MARK: - Connection bindables
    
    lazy var playedAction: Action<DMEventSong, Void> = {
        return Action(workFactory: { [unowned self] (song: DMEventSong) -> Observable<Void> in
            return self.songPersistenceService.markAsPlayed(song: song).map { _ in }
        })
    }()
    
    lazy var onSongCreate: CocoaAction = {
        return CocoaAction { [unowned self] in
            return self.songPersistenceService
                .createSong(title: "songy")
                .map { _ in }
        }
    }()
    
    func onUpvote(song: DMEventSong) -> CocoaAction {
        return CocoaAction {
            return self.songPersistenceService
                .upvote(song: song)
                .map { _ in }
        }
    }
}
