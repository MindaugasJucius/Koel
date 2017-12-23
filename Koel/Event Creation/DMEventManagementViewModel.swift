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

class DMEventManagementViewModel: ViewModelType, BackgroundDisconnectType {
    
    private let disposeBag = DisposeBag()
    
    private let peers = BehaviorSubject<[EventPeerSection]>(value: [EventPeerSection(model: "", items: [])])
    
    let sceneCoordinator: SceneCoordinatorType
    let multipeerService: DMEventMultipeerService
    let songSharing: DMEventSongSharingViewModelType

    var backgroundTaskID = UIBackgroundTaskInvalid
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType,
         multipeerService: DMEventMultipeerService,
         songSharingViewModel: DMEventSongSharingViewModelType) {
        
        self.sceneCoordinator = sceneCoordinator
        self.songSharing = songSharingViewModel
        self.multipeerService = multipeerService
        
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
    private var incommingInvitations: Observable<(DMEventPeer, (Bool) -> (), Bool)> {
        return multipeerService
            .incomingPeerInvitations()
            .map { (client, context, handler) in
                
                guard let contextDictionary = context else {
                    return (DMEventPeer.peer(withPeerID: client, context: nil), handler, false)
                }
                
                let reconnectKey = DMEventPeerPersistenceContexts.ContextKeys.reconnect.rawValue
                let isReconnect = contextDictionary[reconnectKey] != nil
                let eventPeer = DMEventPeer.peer(
                    withPeerID: client,
                    context: contextDictionary as? [String : String]
                )
                
                return (eventPeer, handler, isReconnect)
            }
            .share()
    }
    
    // MARK: shared
    private var allPeersSectioned: Observable<[EventPeerSection]> {
        return Observable
            .of(multipeerService.nearbyFoundPeers(),
                multipeerService.connectedPeers())
            .merge()
            .map { results in
                let peersWithoutHosts = results.filter { !$0.isHost }
                
                let connectedPeers = peersWithoutHosts.filter { $0.isConnected }
                let nearbyPeers = peersWithoutHosts.filter { !$0.isConnected }
                
                print("sectioned peers OBSERVABLES RESULTS:")
                print(results.map { return "\(String(describing: $0.peerID?.displayName)) \($0.isConnected)" })
                
                return [
                    EventPeerSection(model: UIConstants.strings.joinedPeers, items: connectedPeers),
                    EventPeerSection(model: UIConstants.strings.nearbyPeers, items: nearbyPeers)
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
        
        allPeersSectioned
            .subscribe(peers.asObserver())
            .disposed(by: disposeBag)
        
        incommingParticipantReconnectInvitations
            .subscribe(onNext: { handler in
                handler(true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Connection bindables
    
    private func onInvitesClose() -> CocoaAction {
        return CocoaAction {
            return self.sceneCoordinator.pop(animated: true)
        }
    }
    
    // MARK: - shared/rename
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
    
}
