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

class DMEventSearchViewModel: MultipeerViewModelType {
    
    private let disposeBag = DisposeBag()
    
    let multipeerService = DMEventMultipeerService(asEventHost: false)
    private let reachabilityService = try! DefaultReachabilityService()
    
    let sceneCoordinator: SceneCoordinatorType & CoordinatorTransitioning
    
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
        return multipeerService
            .latestConnectedPeer()
            .filter { $0.isHost }
    }
    
    private lazy var pushEventParticipation: Action<DMEventPeer, Void> = {
        return Action (
            workFactory: { [unowned self] host in
                return self.sceneCoordinator.transitionToParticipationScene(withMultipeerService: self.multipeerService,
                                                                            eventHost: host)
            }
        )
    }()
    
    lazy var pushEventManagement: CocoaAction = {
        return CocoaAction { _ in
            self.multipeerService.stopAdvertising()
            self.multipeerService.stopBrowsing()
            self.multipeerService.disconnect()
            return self.sceneCoordinator.transitionToHostScene()
        }
    }()

    lazy var requestAccess: Action<(DMEventPeer), Void> = {
        return Action (
            workFactory: { (eventPeer: DMEventPeer) in
                return self.multipeerService.connect(eventPeer.peerID, context: nil)
            }
        )
    }()
    
    required init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType & CoordinatorTransitioning) {
        self.sceneCoordinator = sceneCoordinator
        
        multipeerService.startAdvertising()
        multipeerService.startBrowsing()
        
        host
            .observeOn(MainScheduler.instance)
            .subscribe(pushEventParticipation.inputs)
            .disposed(by: disposeBag)

    }
}
