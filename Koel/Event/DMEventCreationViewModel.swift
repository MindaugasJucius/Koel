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

    let multipeerEventService = DMEventMultipeerService(withDisplayName: UIDevice.current.name)
    
    var allPeers: Observable<[DMEventPeer]> {
        return multipeerEventService.nearbyFoundPeers()
    }
    
    var connectedPeers: Observable<[DMEventPeer]> {
        return multipeerEventService.connectedPeers()
    }
    
    var latestConnectedPeer: Observable<DMEventPeer> {
        return multipeerEventService.latestConnectedPeer()
    }
    
    var incommingInvitations: Observable<(DMEventPeer, (Bool) -> ())> {
        return multipeerEventService.incomingPeerInvitations().map({ (client, context, handler) in
            let eventPeer = DMEventPeer.init(withContext: context as? [String : String], peerID: client)
            return (eventPeer, handler)
        })
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
