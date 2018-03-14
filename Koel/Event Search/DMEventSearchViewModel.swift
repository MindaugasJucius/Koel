//
//  DMEventSearchingViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 01/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Action
import RxSwift
import MultipeerConnectivity

class DMEventSearchViewModel: ViewModelType, MultipeerViewModelType {
    
    private let disposeBag = DisposeBag()
    
    let multipeerService = DMEventMultipeerService(asEventHost: false)
    
    let sceneCoordinator: SceneCoordinatorType

    var incommingInvitations: Observable<(DMEventPeer, (Bool) -> ())> {
        return multipeerService
            .incomingPeerInvitations()
            .map { (client, context, handler) in
                let eventPeer = DMEventPeer.peer(withPeerID: client, context: context as? [String : String])
                return (eventPeer, handler)
            }
            .filter {
                $0.0.isHost
            }
    }
    
    var hosts: Observable<[DMEventPeer]> {
        return multipeerService.nearbyFoundHostPeers()
    }
    
    var host: Observable<DMEventPeer> {
        return multipeerService.latestConnectedPeer()
    }
    
    lazy var pushParticipation: Action<DMEventPeer, Void> = {
        return Action (
            workFactory: { [unowned self] host in
                
                let songSharingViewModel = DMEventSongSharingViewModel(
                    songPersistenceService: DMEventSongPersistenceService(),
                    songSharingService: DMEntitySharingService(),
                    multipeerService: self.multipeerService
                )
                let participationModel = DMEventParticipationViewModel(host: host, songSharingViewModel: songSharingViewModel)

                let participationScene = Scene.participation(participationModel)
                return self.sceneCoordinator.transition(to: participationScene, type: .rootWithNavigationVC)
            }
        )
    }()
    
    lazy var pushCreateEvent: CocoaAction = { this in
        return CocoaAction { _ in
            this.multipeerService.stopAdvertising()
            this.multipeerService.stopBrowsing()
            this.multipeerService.disconnect()
            
            let songSharingViewModel = DMEventSongSharingViewModel(
                songPersistenceService: DMEventSongPersistenceService(),
                songSharingService: DMEntitySharingService(),
                multipeerService: DMEventMultipeerService(asEventHost: true)
            )
            
            let manageEventViewModel = DMEventManagementViewModel(
                sceneCoordinator: this.sceneCoordinator,
                songSharingViewModel: songSharingViewModel
            )
            
            return self.sceneCoordinator.transition(
                to: Scene.manage(manageEventViewModel),
                type: .rootWithNavigationVC
            )
        }
    }(self)

    lazy var requestAccess: Action<(DMEventPeer), Void> = { this in
        return Action (
            workFactory: { (eventPeer: DMEventPeer) in
                return this.multipeerService.connect(eventPeer.peerID, context: nil)
            }
        )
    }(self)
    
    required init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
        
        multipeerService.startAdvertising()
        multipeerService.startBrowsing()
        
        host
            .observeOn(MainScheduler.instance)
            .subscribe(pushParticipation.inputs)
            .disposed(by: disposeBag)

    }
}
