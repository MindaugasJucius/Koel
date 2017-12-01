//
//  DMEventAdvertiser.swift
//  Koel
//
//  Created by Mindaugas Jucius on 30/11/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import MultipeerConnectivity
import RxSwift

fileprivate let IdentityCacheKey = "IdentityCacheKey"
fileprivate let EventServiceType = "song-event"

class DMEventMultipeerService: NSObject {
    
    fileprivate let myPeerID: MCPeerID

    fileprivate let advertiser: MCNearbyServiceAdvertiser
    fileprivate let browser: MCNearbyServiceBrowser
    fileprivate let session: MCSession
    
    fileprivate let incomingConnections: PublishSubject<(MCPeerID, [String: Any]?, (Bool, MCSession?) -> Void)> = PublishSubject()
    fileprivate let nearbyPeers: Variable<[(MCPeerID, [String: String]?)]> = Variable([])
    
    fileprivate let connections = Variable<[MCPeerID]>([])
    fileprivate let connectionErrors: PublishSubject<Error> = PublishSubject()
    
    init(withDisplayName displayName: String) {
        self.myPeerID = DMEventMultipeerService.retrieveIdentity(withDisplayName: displayName)
        
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: EventServiceType)
        
        self.session = MCSession(
            peer: self.myPeerID,
            securityIdentity: nil,
            encryptionPreference: .none)
        
        self.browser = MCNearbyServiceBrowser(
            peer: self.session.myPeerID,
            serviceType: EventServiceType)
        
        super.init()
    
        advertiser.delegate = self
        browser.delegate = self
    }
    
    func startAdvertisingEvent() {
        advertiser.startAdvertisingPeer()
    }
    
    /// Retrieve MCPeerID from UserDefaults if one exists, or create and store a new one
    ///
    /// - Parameter displayName: string to display to browsers
    /// - Returns: identity
    private static func retrieveIdentity(withDisplayName displayName: String) -> MCPeerID {
        if let data = UserDefaults.standard.data(forKey: IdentityCacheKey),
            let peerID = NSKeyedUnarchiver.unarchiveObject(with: data) as? MCPeerID,
            peerID.displayName == displayName {
            return peerID
        }
        
        let identity = MCPeerID(displayName: displayName)
        
        let identityData = NSKeyedArchiver.archivedData(withRootObject: identity)
        UserDefaults.standard.set(identityData, forKey: IdentityCacheKey)
        
        return identity
    }
    
}

extension DMEventMultipeerService: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        
    }
    
}

extension DMEventMultipeerService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("did not start advertising due to: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("received invitation from peer: \(peerID)")
    }
    
}
