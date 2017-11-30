//
//  DMEventAdvertiser.swift
//  Koel
//
//  Created by Mindaugas Jucius on 30/11/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import MultipeerConnectivity

class DMEventAdvertiserService: NSObject {

    private let EventServiceType = "song-event"
    
    private let myPeerID: MCPeerID
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    
    init(withPeerID peerID: String) {
        self.myPeerID = MCPeerID(displayName: peerID)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID,
                                                           discoveryInfo: nil,
                                                           serviceType: EventServiceType)
        super.init()
        serviceAdvertiser.delegate = self
    }
    
    func startAdvertisingEvent() {
        serviceAdvertiser.startAdvertisingPeer()
    }
    
}

extension DMEventAdvertiserService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("did not start advertising due to: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("received invitation from peer: \(peerID)")
    }
    
}
