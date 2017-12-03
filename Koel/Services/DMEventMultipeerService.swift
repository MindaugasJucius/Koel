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
    
    fileprivate let myEventPeer: DMEventPeer

    fileprivate let advertiser: MCNearbyServiceAdvertiser
    fileprivate let browser: MCNearbyServiceBrowser
    fileprivate let session: MCSession
    
    fileprivate let incomingInvitations: PublishSubject<(MCPeerID, [String: Any]?, (Bool, MCSession?) -> Void)> = PublishSubject()
    fileprivate let nearbyPeers: Variable<[DMEventPeer]> = Variable([])
    fileprivate let connections = Variable<[DMEventPeer]>([])
    
    fileprivate let latestConnection = PublishSubject<DMEventPeer>()
    
    fileprivate let advertisingConnectionErrors: PublishSubject<MCError> = PublishSubject()
    fileprivate let browsingConnectionErrors: PublishSubject<MCError> = PublishSubject()
    
    fileprivate let receivedData: PublishSubject<(MCPeerID, Data)> = PublishSubject()
    
    init(withDisplayName displayName: String) {
        self.myEventPeer = DMEventMultipeerService.retrieveIdentity(withDisplayName: displayName)
        
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: myEventPeer.peerID,
            discoveryInfo: nil,
            serviceType: EventServiceType)
        
        self.session = MCSession(
            peer: myEventPeer.peerID,
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
    
    func incomingPeerInvitations() -> Observable<(MCPeerID, [String: Any]?, (Bool) -> ())> {
        return incomingInvitations
            .map { [unowned self] (client, context, handler) in
                // Do not expose session to observers
                return (client, context, { (accept: Bool) in
                    handler(accept, self.session)
                })
        }
    }
    
    func connectedPeers() -> Observable<[DMEventPeer]> {
        return connections.asObservable()
    }
    
    func latestConnectedPeer() -> Observable<DMEventPeer> {
        return latestConnection.asObservable()
    }
    
    func advertisingErrors() -> Observable<MCError> {
        return advertisingConnectionErrors.asObservable()
    }
    
    func browsingErrors() -> Observable<MCError> {
        return advertisingConnectionErrors.asObservable()
    }
    
    func nearbyFoundPeers() -> Observable<[DMEventPeer]> {
        return nearbyPeers.asObservable()
    }
    
    //MARK: - Lifecycle management
    
    func disconnect() {
        self.session.disconnect()
    }
    
    //MARK: - Advertising
    
    func startAdvertising() -> Observable<Void> {
        return .just(advertiser.startAdvertisingPeer())
    }
    
    func stopAdvertising() -> Observable<Void> {
        return .just(advertiser.stopAdvertisingPeer())
    }

    //MARK: - Browsing
    
    func startBrowsing() -> Observable<Void> {
        return .just(browser.startBrowsingForPeers())
    }
    
    func stopBrowsing() -> Observable<Void> {
        nearbyPeers.value = []
        return .just(browser.stopBrowsingForPeers())
    }
    
    func connect(_ peer: MCPeerID, context: [String: Any]?, timeout: TimeInterval) -> Observable<Void> {
        guard let context = context,
            let data = try? JSONSerialization.data(withJSONObject: context, options: JSONSerialization.WritingOptions()) else {
            return .just(browser.invitePeer(peer, to: self.session, withContext: nil, timeout: timeout))
        }
    
        return .just(browser.invitePeer(peer, to: self.session, withContext: data, timeout: timeout))
    }
    
    /// Retrieve DMEventPeer from UserDefaults if one exists, or create and store a new one
    ///
    /// - Parameter displayName: string to display to browsers
    /// - Returns: identity
    private static func retrieveIdentity(withDisplayName displayName: String) -> DMEventPeer {
        if let data = UserDefaults.standard.data(forKey: IdentityCacheKey),
            let eventPeer = NSKeyedUnarchiver.unarchiveObject(with: data) as? DMEventPeer,
            eventPeer.peerDeviceDisplayName == displayName {
            return eventPeer
        }
        
        let identity = DMEventPeer.init(peerID: MCPeerID(displayName: displayName))
        
        let identityData = NSKeyedArchiver.archivedData(withRootObject: identity)
        UserDefaults.standard.set(identityData, forKey: IdentityCacheKey)
        
        return identity
    }
    
    //MARK: - Sending
    
    func send(toPeer other: MCPeerID,
              data: Data,
              mode: MCSessionSendDataMode) -> Observable<()> {
        return Observable.create { observer in
            do {
                try self.session.send(data, toPeers: [other], with: mode)
                observer.on(.next(()))
                observer.on(.completed)
            } catch let error {
                observer.on(.error(error))
            }
            
            // There's no way to cancel this operation,
            // so do nothing on dispose.
            return Disposables.create {}
        }
    }
    
    //MARK: - Receiving
    
    func receive() -> Observable<(MCPeerID, Data)> {
        return receivedData
    }
    
}

extension DMEventMultipeerService: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        var result: [DMEventPeer] = []
        let eventPeer = DMEventPeer.init(withContext: info, peerID: peerID)

        if nearbyPeers.value.map({ $0.peerID }).index(of: peerID) == .none {
            result = nearbyPeers.value + [eventPeer]
        }
                
        self.nearbyPeers.value = result
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        nearbyPeers.value = nearbyPeers.value.filter { existingNearbyPeer in
            return existingNearbyPeer.peerID != peerID
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        let mcError = MCError(_nsError: error as NSError)
        browsingConnectionErrors.onNext(mcError)
    }
    
}

extension DMEventMultipeerService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        let mcError = MCError(_nsError: error as NSError)
        advertisingConnectionErrors.onNext(mcError)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        guard let context = context, let json = try? JSONSerialization.jsonObject(with: context) else {
            incomingInvitations.onNext((peerID, nil, invitationHandler))
            return
        }

        incomingInvitations.onNext((peerID, json as? [String: Any], invitationHandler))
    }
    
}

extension DMEventMultipeerService: MCSessionDelegate {

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            let filtered = nearbyPeers.value.filter { $0.peerID == peerID }
            guard let matchingNearbyPeer = filtered.first else {
                return
            }
            latestConnection.onNext(matchingNearbyPeer)
        }
        
        if state != .connecting {
            var eventPeerConnections: [DMEventPeer] = []
            
            nearbyPeers.value.forEach({ eventPeer in
                if session.connectedPeers.index(of: eventPeer.peerID) != .none {
                    eventPeerConnections.append(eventPeer)
                }
            })
            
            connections.value = eventPeerConnections
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        receivedData.on(.next((peerID, data)))
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
}

