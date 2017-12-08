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

class DMEventManagementViewModel: ViewModelType, BackgroundDisconnectType {
    
    private let disposeBag = DisposeBag()
    
    private let peers = BehaviorSubject<[EventPeerSection]>(value: [EventPeerSection(model: "", items: [])])
    
    let sceneCoordinator: SceneCoordinatorType
    let songPersistanceService: DMEventSongPersistenceServiceType
    let multipeerService: DMEventMultipeerService

    var backgroundTaskID = UIBackgroundTaskInvalid
    
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
    
    var incommingParticipantInvitations: Observable<(DMEventPeer, (Bool) -> ())> {
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
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType, songPersistanceService: DMEventSongPersistenceServiceType) {
        self.sceneCoordinator = sceneCoordinator
        self.songPersistanceService = songPersistanceService
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
        
        incommingParticipantInvitations
            .subscribe(onNext: { invitation in
                let alert = UIAlertController(title: "Connection request", message: "\(invitation.0.peerDeviceDisplayName) wants to join your party", preferredStyle: .alert)
                let connectAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
                    let invitationHandler = invitation.1
                    invitationHandler(true)
                })
                alert.addAction(connectAction)
                sceneCoordinator.currentViewController.present(
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
}
