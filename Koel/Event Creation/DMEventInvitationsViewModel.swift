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

struct DMEventInvitationsViewModel: ViewModelType, MultipeerViewModelType {
    
    private let disposeBag = DisposeBag()
    
    let multipeerService: DMEventMultipeerService
    let sceneCoordinator: SceneCoordinatorType
    
    let onClose: CocoaAction
    
    var allPeersSectioned: Observable<[EventPeerSection]> {
        return multipeerService.allPeers()
            .map { results in
                let participantPeers = results.filter { !$0.isHost }
                
                let connectedPeers = participantPeers.filter { $0.isConnected }
                let nearbyPeers = participantPeers.filter { !$0.isConnected }
                
                let sections = [
                    EventPeerSection(model: UIConstants.strings.joinedPeers, items: connectedPeers),
                    EventPeerSection(model: UIConstants.strings.nearbyPeers, items: nearbyPeers)
                ]
                
                return sections
            }
            .observeOn(MainScheduler.instance)
    }
    
    //MARK: - Actions
    
    lazy var inviteAction: Action<(DMEventPeer), Void> = { this in
        return Action(
            workFactory: { (eventPeer: DMEventPeer) in
                let hostContext = DMEventPeerPersistenceContexts.hostDiscovery
                return this.multipeerService.connect(eventPeer.peerID, context: hostContext)
            }
        )
    }(self)
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType,
         multipeerService: DMEventMultipeerService,
         onClose: CocoaAction) {
        self.sceneCoordinator = sceneCoordinator
        self.multipeerService = multipeerService
        self.onClose = onClose
    }
    
}
