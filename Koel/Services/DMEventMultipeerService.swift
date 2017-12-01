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
        session.delegate = self
    }
    
    //MARK: - Observables
    
    func incomingPeerConnections() -> Observable<(MCPeerID, [String: Any]?, (Bool) -> ())> {
        return incomingConnections
            .map { [unowned self] (client, context, handler) in
                // Do not expose session to observers
                return (client, context, { (accept: Bool) in
                        handler(accept, self.session)
                })
        }
    }

    func peerConnectionErrors() -> Observable<Error> {
        return connectionErrors
    }
    
    func connectedPeers() -> Observable<[MCPeerID]> {
        return connections.asObservable()
    }
    
    func nearbyFoundPeers() -> Observable<[(MCPeerID, [String: String]?)]> {
        return nearbyPeers.asObservable()
    }
    
    //MARK: - Lifecycle management
    
    func disconnect() {
        self.session.disconnect()
    }
    
    //MARK: - Advertising
    
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
    }

    //MARK: - Browsing
    
    func startBrowsing() {
        browser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
        nearbyPeers.value = []
    }
    
    func connect(_ peer: MCPeerID, context: [String: Any]?, timeout: TimeInterval) {
        guard let context = context,
            let data = try? JSONSerialization.data(withJSONObject: context, options: JSONSerialization.WritingOptions()) else {
            browser.invitePeer(peer, to: self.session, withContext: nil, timeout: timeout)
            return
        }
    
        browser.invitePeer(peer, to: self.session, withContext: data, timeout: timeout)
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
        var result: [(MCPeerID, [String: String]?)] = []
        for peerIDWithInfo in (self.nearbyPeers.value + [(peerID, info)]) {
            
            if (result.map { $0.0 }).index(of: peerIDWithInfo.0) == nil {
                result = result + [peerIDWithInfo]
            }
            
        }
        
        self.nearbyPeers.value = result
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        nearbyPeers.value = nearbyPeers.value.filter { (existingPeerID, _) -> Bool in
            return existingPeerID != peerID
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        connectionErrors.onNext(error)
    }
    
}

extension DMEventMultipeerService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        connectionErrors.onNext(error)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        guard let context = context, let json = try? JSONSerialization.jsonObject(with: context) else {
            incomingConnections.onNext((peerID, nil, invitationHandler))
            return
        }

        incomingConnections.onNext((peerID, json as? [String: Any], invitationHandler))
    }
    
}

extension DMEventMultipeerService: MCSessionDelegate {

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // Only emit to observers when peer has connected
        if state != .connecting {
            connections.value = session.connectedPeers
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
}

