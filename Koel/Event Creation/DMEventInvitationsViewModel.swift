//
//  DMEventInvitationsViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 30/11/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import MultipeerConnectivity
import RxSwift
import Action

struct DMEventInvitationsViewModel: ViewModelType {

    private let disposeBag = DisposeBag()
    
    private let multipeerEventService: DMEventMultipeerService
    let sceneCoordinator: SceneCoordinatorType
    
    let onClose: CocoaAction
    
    let allPeersSectioned: Observable<[EventPeerSection]>
    
    var latestConnectedPeer: Observable<DMEventPeer> {
        return multipeerEventService.latestConnectedPeer()
    }
    
    //MARK: - Actions
    
    lazy var inviteAction: Action<(DMEventPeer), Void> = { this in
        return Action(
            workFactory: { (eventPeer: DMEventPeer) in
                let hostContext = MultipeerEventContexts.hostDiscovery
                return this.multipeerEventService.connect(eventPeer.peerID, context: hostContext)
            }
        )
    }(self)
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType,
         multipeerService: DMEventMultipeerService,
         peers: Observable<[EventPeerSection]>,
         onClose: CocoaAction) {
        self.sceneCoordinator = sceneCoordinator
        self.multipeerEventService = multipeerService
        self.onClose = onClose
        self.allPeersSectioned = peers
    }
    
}
