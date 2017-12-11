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
    let multipeerService = DMEventMultipeerService(
        withDisplayName: UIDevice.current.name,
        asEventHost: false
    )
    
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
    
    private lazy var pushManagement: Action<DMEventPeer, Void> = {
        return Action (
            workFactory: { [unowned self] host in
                let participationModel = DMEventParticipantViewModel(withMultipeerService: self.multipeerService, withHost: host)
                let participationScene = Scene.participation(participationModel)
                return self.sceneCoordinator.transition(to: participationScene, type: .root)
            }
        )
    }()
    
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
            .subscribe(pushManagement.inputs)
            .disposed(by: disposeBag)
    }
}
