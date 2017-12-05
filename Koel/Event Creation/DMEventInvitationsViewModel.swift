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

    private let multipeerEventService = DMEventMultipeerService(withDisplayName: UIDevice.current.name, asEventHost: true)
    let sceneCoordinator: SceneCoordinatorType
    
    var allPeersSectioned: Observable<[EventPeerSection]> {
        return Observable
            .of(multipeerEventService.nearbyFoundPeers(),
                multipeerEventService.connectedPeers())
            .merge()
            .map { results in

                let connectedPeers = results.filter { $0.isConnected }
                let notConnectedPeers = results.filter { !$0.isConnected }
                
                return [
                    EventPeerSection(model: "Joined", items: connectedPeers),
                    EventPeerSection(model: "Nearby", items: notConnectedPeers)
                ]
        }
    }
    
    var connectedPeers: Observable<[DMEventPeer]> {
        return multipeerEventService.connectedPeers()
    }
    
    var latestConnectedPeer: Observable<DMEventPeer> {
        return multipeerEventService.latestConnectedPeer()
    }
    
    //MARK: - Actions
    
    var incommingParticipantInvitations: Observable<(DMEventPeer, (Bool) -> ())> {
        return multipeerEventService
            .incomingPeerInvitations()
            .map { (client, context, handler) in
                let eventPeer = DMEventPeer.init(withContext: context as? [String : String], peerID: client)
                return (eventPeer, handler)
        }
    }
    
    lazy var inviteAction: Action<(DMEventPeer), Void> = { this in
        return Action(
            workFactory: { (eventPeer: DMEventPeer) in
                let hostContext = DMEventMultipeerService.HostDiscoveryInfoDict
                return this.multipeerEventService.connect(eventPeer.peerID, context: hostContext)
            }
        )
    }(self)
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
    }
    
    func onStartAdvertising(){
        self.multipeerEventService.startAdvertising()
    }

    func onStartBrowsing() {
        self.multipeerEventService.startBrowsing()
    }
    
}
