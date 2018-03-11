//
//  DMEventAdvertiser.swift
//  Koel
//
//  Created by Mindaugas Jucius on 30/11/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import MultipeerConnectivity
import RxSwift
import RxOptional

fileprivate let SelfPeerUUIDKey = "SelfPeerUUIDKey"
fileprivate let EventServiceType = "song-event"

class DMEventMultipeerService: NSObject {

    private(set) var myEventPeer: DMEventPeer
    
    private let disposeBag = DisposeBag()
    
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private let session: MCSession
    
    private let peerPersistenceService: DMEventPeerPersistenceServiceType
    
    private let incomingInvitations: PublishSubject<(MCPeerID, [String: Any]?, (Bool, MCSession?) -> Void)> = PublishSubject()
    
    private let nearbyPeers: Variable<[DMEventPeer]> = Variable([])
    private let nearbyHostPeers = PublishSubject<[DMEventPeer]>()
    
    private let connections = Variable<[DMEventPeer]>([])
    
    private let latestConnection = PublishSubject<DMEventPeer>()
    private let latestDisconnection = PublishSubject<DMEventPeer>()
    
    private let advertisingConnectionErrors: PublishSubject<MCError> = PublishSubject()
    private let browsingConnectionErrors: PublishSubject<MCError> = PublishSubject()
    
    private let receivedData: PublishSubject<(MCPeerID, Data)> = PublishSubject()
    
    init(withDisplayName displayName: String = UIDevice.current.name, asEventHost eventHost: Bool, peerPersistenceService: DMEventPeerPersistenceService = DMEventPeerPersistenceService()) {
        self.peerPersistenceService = peerPersistenceService
        
        let selfUUID: String
        
        if let uuid = UserDefaults.standard.string(forKey: SelfPeerUUIDKey) {
            selfUUID = uuid
        } else {
            selfUUID = UUID.init().uuidString
            UserDefaults.standard.set(selfUUID, forKey: SelfPeerUUIDKey)
        }

        let peerID = MCPeerID(displayName: selfUUID)
        
        let myPeer = DMEventPeer.peer(
            withPeerID: peerID,
            storeAsSelf: true,
            storeAsHost: eventHost,
            uuid:selfUUID
        )
        
        self.myEventPeer = myPeer

        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .none
        )
        
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: self.myEventPeer.discoveryContext,
            serviceType: EventServiceType
        )
        
        self.browser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: EventServiceType
        )
        
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
    
    func allPeers() -> Observable<[DMEventPeer]> {
        return Observable.of(connectedPeers(), nearbyFoundPeers()).flatMap { $0 }
    }
    
    func latestConnectedPeer() -> Observable<DMEventPeer> {
        return latestConnection.asObservable()
    }
    
    func latestDisconnectedPeer() -> Observable<DMEventPeer> {
        return latestDisconnection.asObservable()
    }
    
    func advertisingErrors() -> Observable<MCError> {
        return advertisingConnectionErrors.asObservable()
    }
    
    func browsingErrors() -> Observable<MCError> {
        return browsingConnectionErrors.asObservable()
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
    
    func startAdvertising() {
        self.advertiser.startAdvertisingPeer()
    }

    func stopAdvertising() {
        self.advertiser.stopAdvertisingPeer()
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
    
    func connect(_ peer: MCPeerID?, context: [String: Any]?, timeout: TimeInterval = 60) -> Observable<Void> {
        
        guard let peerID = peer else {
            fatalError("peerID is nil")
        }
        
        guard let context = context,
            let data = try? JSONSerialization.data(withJSONObject: context, options: JSONSerialization.WritingOptions()) else {
            return .just(browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: timeout))
        }
    
        return .just(browser.invitePeer(peerID, to: self.session, withContext: data, timeout: timeout))
    }
    
    //MARK: - Sending
    
    func send(toPeers others: [MCPeerID],
              data: Data,
              mode: MCSessionSendDataMode) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.session.send(data, toPeers: others, with: mode)
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
    
    func send(toPeer other: MCPeerID,
              data: Data,
              mode: MCSessionSendDataMode) -> Observable<Void> {
        return send(toPeers: [other], data: data, mode: mode)
    }
    
    //MARK: - Receiving
    
    func receive() -> Observable<(MCPeerID, Data)> {
        return receivedData
    }
    
}

extension DMEventMultipeerService: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer \(peerID.displayName)")
        
        //MultipeerConnectivity finds itself https://stackoverflow.com/questions/22525806/ios-7-multipeer-connectivity-mcnearbyservicebrowser-finds-itself
        guard let discoveredPeerUUID = info?[ContextKeys.uuid("").rawValue],
            discoveredPeerUUID != myEventPeer.uuid else {
            return
        }
        
        peerPersistenceService
            .peerExists(withUUID: peerID.displayName)
            .catchError { (error) -> Observable<DMEventPeer> in
                if let peerPersistenceError = error as? DMEventPeerPersistenceServiceError {
                    switch peerPersistenceError {
                    case .peerDoesNotExist:
                        let unmanagedPeer = DMEventPeer.peer(withPeerID: peerID, context: info)
                        print("peer does not exist - will attempt to store")
                        return self.peerPersistenceService.store(peer: unmanagedPeer)
                    default:
                        print("peer checking failed")
                        return Observable.empty()
                    }
                }
                return Observable.empty()
            }
            .subscribe(
                onNext: { [unowned self] peer in
                    if !self.nearbyPeers.value.contains(peer) {
                        self.nearbyPeers.value = self.nearbyPeers.value + [peer]
                    } else {
                        self.nearbyPeers.value = self.nearbyPeers.value
                    }
                    self.nearbyHostPeers.onNext(self.nearbyPeers.value.filter { $0.isHost })
                    print("nearby peers: \n \(self.nearbyPeers.value.map { "\($0.peerID?.displayName) ishost \($0.isHost) \n" })")
                }
            )
            .disposed(by: disposeBag)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("browser lostPeer \(peerID.displayName)")
        guard let matchingPeer = nearbyPeers.value.filter ({ $0.peerID == peerID }).first else {
            return
        }
        
        nearbyPeers.value = nearbyPeers.value.filter { $0 != matchingPeer }
        nearbyHostPeers.onNext(nearbyPeers.value.filter { $0.isHost })
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers because of an error \(error.localizedDescription)")
        let mcError = MCError(_nsError: error as NSError)
        browsingConnectionErrors.onNext(mcError)
    }
    
}

extension DMEventMultipeerService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer because of an error \(error.localizedDescription)")
        let mcError = MCError(_nsError: error as NSError)
        advertisingConnectionErrors.onNext(mcError)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let context = context, let json = try? JSONSerialization.jsonObject(with: context) else {
            print("didReceiveInvitationFromPeer \(peerID.displayName) with no info")
            incomingInvitations.onNext((peerID, nil, invitationHandler))
            return
        }
        print("didReceiveInvitationFromPeer \(peerID.displayName) with info \((json as? [String: Any])?.keys)")
        incomingInvitations.onNext((peerID, json as? [String: Any], invitationHandler))
    }
    
}

extension DMEventMultipeerService: MCSessionDelegate {

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("\(peerID.displayName) changed to state \(state.rawValue)")
        if state != .connecting {
            peerPersistenceService
                .peerExists(withUUID: peerID.displayName)
                .subscribe(
                    onNext: { [unowned self] peer in
                        self.performUpdate(forPeer: peer, toConnectedState: state == .connected)
                    },
                    onError: { error in
                        print("peer state change failed - \(error)")
                    }
                )
                .disposed(by: disposeBag)
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

extension DMEventMultipeerService {
    
    func performUpdate(forPeer peer: DMEventPeer, toConnectedState connected: Bool) {
        let peerUpdate: PeerUpdate = {
            $0.isConnected = connected
            return $0
        }
        
        peerPersistenceService.update(peer: peer, updateBlock: peerUpdate)
        .subscribe(
            onNext: { [unowned self] updatedPeer in
                //Is a currently connected peer changing state
                let currentConnection = self.connections.value.filter { $0.peerID == updatedPeer.peerID }.first
                
                if connected {
                    NSLog("new connection \(peer.peerID?.displayName)")
                    self.latestConnection.onNext(updatedPeer)
                    //Emit to connections observable only if this is a new connection
                    if currentConnection == .none {
                        self.connections.value = self.connections.value + [updatedPeer]
                    }
                } else if let currentlyConnected = currentConnection { // Filter out disconnected peer
                    self.connections.value = self.connections.value.filter {  $0.peerID != currentlyConnected.peerID }
                }
                
                print("CURRENT CONNECTIONS \(self.connections.value.map { $0.peerID?.displayName })")
            },
            onError: { error in
            
            }
        ).disposed(by: disposeBag)
    }
}

