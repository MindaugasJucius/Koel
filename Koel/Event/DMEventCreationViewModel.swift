//
//  DMEventCreationViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 30/11/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import MultipeerConnectivity
import RxSwift
import Action

struct DMEventCreationViewModel {

    private let multipeerEventService = DMEventMultipeerService(withDisplayName: UIDevice.current.name)
    private let sceneCoordinator: SceneCoordinatorType
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
    }
    
    var allPeers: Observable<[DMEventPeer]> {
        return multipeerEventService.nearbyFoundPeers()
    }
    
    var connectedPeers: Observable<[DMEventPeer]> {
        return multipeerEventService.connectedPeers()
    }
    
    var latestConnectedPeer: Observable<DMEventPeer> {
        return multipeerEventService.latestConnectedPeer()
    }
    
    //MARK: - Actions
    
    lazy var inviteAction: Action<(DMEventPeer, [String: Any]?), Void> = { this in
        return Action(
            workFactory: { (eventPeer: DMEventPeer, context: [String: Any]?) in
                return this.multipeerEventService.connect(eventPeer.peerID, context: context, timeout: 60)
            }
        )
    }(self)
    
    func onStartAdvertising() -> CocoaAction {
        return CocoaAction(
            workFactory: {
                return self.multipeerEventService.startAdvertising()
            }
        )
    }

    func onStartBrowsing() -> CocoaAction {
        return CocoaAction(
            workFactory: {
                return self.multipeerEventService.startBrowsing()
            }
        )
    }
    
}
