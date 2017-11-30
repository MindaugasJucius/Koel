//
//  MCNearbyServiceAdvertiserDelegate+Rx.swift
//  Koel
//
//  Created by Mindaugas Jucius on 30/11/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import RxSwift
import RxCocoa

class RxMCNearbyServiceAdvertiserDelegateProxy: DelegateProxy<AnyObject, AnyObject>, DelegateProxyType, MCNearbyServiceAdvertiserDelegate {
    
    static func registerKnownImplementations() {
        
    }
    
    static func currentDelegate(for object: AnyObject) -> AnyObject? {
        <#code#>
    }
    
    static func setCurrentDelegate(_ delegate: AnyObject?, to object: AnyObject) {
        <#code#>
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        <#code#>
    }
    

}
