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

typealias PeerWithContext = (MCPeerID, [String: String]?)

struct DMEventCreationViewModel {

    let multipeerEventService = DMEventMultipeerService(withDisplayName: UIDevice.current.name)
    
    var allPeers: Observable<[PeerWithContext]> {
        return multipeerEventService.nearbyFoundPeers()
    }
    
    var connectedPeers: Observable<[MCPeerID]> {
        return multipeerEventService.connectedPeers().skip(1)
    }
    
    var latestConnectedPeer: Observable<MCPeerID> {
        return multipeerEventService.latestConnectedPeer()
    }
    
    var incommingInvitations: Observable<(MCPeerID, [String: Any]?, (Bool) -> ())> {
        return multipeerEventService.incomingPeerInvitations()
    }
    
    //MARK: - Actions
    
    lazy var inviteAction: Action<(MCPeerID, [String: Any]?), Void> = { this in
        return Action(
            workFactory: { (peerID: MCPeerID, context: [String: Any]?) in
                return this.multipeerEventService.connect(peerID, context: context, timeout: 60)
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
