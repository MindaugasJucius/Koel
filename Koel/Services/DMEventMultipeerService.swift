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

    static let HostDiscoveryInfoDict = [Peer.isHost.rawValue: "true"]
    
    private let myEventPeer: DMEventPeer
    private let asEventHost: Bool
    
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private let session: MCSession
    
    private let incomingInvitations: PublishSubject<(MCPeerID, [String: Any]?, (Bool, MCSession?) -> Void)> = PublishSubject()
    
    private let nearbyPeers: Variable<[DMEventPeer]> = Variable([])
    private let nearbyHostPeers: Variable<[DMEventPeer]> = Variable([])
    
    private let connections = Variable<[DMEventPeer]>([])
    
    private let latestConnection = PublishSubject<DMEventPeer>()
    
    private let advertisingConnectionErrors: PublishSubject<MCError> = PublishSubject()
    private let browsingConnectionErrors: PublishSubject<MCError> = PublishSubject()
    
    private let receivedData: PublishSubject<(MCPeerID, Data)> = PublishSubject()
    
    init(withDisplayName displayName: String, asEventHost eventHost: Bool) {
        self.myEventPeer = DMEventMultipeerService.retrieveIdentity(withDisplayName: displayName, asHost: eventHost)
        self.asEventHost = eventHost
        
        self.session = MCSession(
            peer: myEventPeer.peerID,
            securityIdentity: nil,
            encryptionPreference: .none)
        
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: self.session.myPeerID,
            discoveryInfo: eventHost ? DMEventMultipeerService.HostDiscoveryInfoDict : nil,
            serviceType: EventServiceType)
        
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
    
    func nearbyFoundHostPeers() -> Observable<[DMEventPeer]> {
        return nearbyHostPeers.asObservable()
    }
    
    //MARK: - Lifecycle management
    
    func disconnect() {
        self.session.disconnect()
    }
    
    //MARK: - Advertising
    
    @discardableResult
    func startAdvertising() -> Observable<Void> {
        return .just(advertiser.startAdvertisingPeer())
    }

    @discardableResult
    func stopAdvertising() -> Observable<Void> {
        return .just(advertiser.stopAdvertisingPeer())
    }

    //MARK: - Browsing
    
    @discardableResult
    func startBrowsing() -> Observable<Void> {
        return .just(browser.startBrowsingForPeers())
    }
    
    @discardableResult
    func stopBrowsing() -> Observable<Void> {
        nearbyPeers.value = []
        return .just(browser.stopBrowsingForPeers())
    }
    
    func connect(_ peer: MCPeerID, context: [String: Any]?, timeout: TimeInterval = 60) -> Observable<Void> {
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
    private static func retrieveIdentity(withDisplayName displayName: String, asHost host: Bool) -> DMEventPeer {
        if let data = UserDefaults.standard.data(forKey: IdentityCacheKey),
            let eventPeer = NSKeyedUnarchiver.unarchiveObject(with: data) as? DMEventPeer,
            eventPeer.peerDeviceDisplayName == displayName {
            return eventPeer
        }
        
        let peerID = MCPeerID(displayName: displayName)
        let identity = DMEventPeer.init(peerID: peerID, isHost: host)
        
        let identityData = NSKeyedArchiver.archivedData(withRootObject: identity)
        UserDefaults.standard.set(identityData, forKey: IdentityCacheKey)
        
        return identity
    }
    
    //MARK: - Sending
    
    func send(toPeer other: MCPeerID,
              data: Data,
              mode: MCSessionSendDataMode) -> Observable<Void> {
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
        self.nearbyHostPeers.value = result.filter { $0.isHost }
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
                    eventPeer.isConnected = state == .connected
                }
            })
            
            connections.value = eventPeerConnections
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let string = String(data: data, encoding: .utf8)
        print("msg \(string)")
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

