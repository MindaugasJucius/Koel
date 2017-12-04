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

struct DMEventCreationViewModel: ViewModelType {

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
                    EventPeerSection(model: "Connected", items: connectedPeers),
                    EventPeerSection(model: "Not connected", items: notConnectedPeers)
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
    
    lazy var inviteAction: Action<(DMEventPeer), Void> = { this in
        return Action(
            workFactory: { (eventPeer: DMEventPeer) in
                let hostContext = DMEventMultipeerService.HostDiscoveryInfoDict
                return this.multipeerEventService.connect(eventPeer.peerID, context: hostContext, timeout: 60)
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
