//
//  DMEventPeerPersistenceServiceType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 09/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import MultipeerConnectivity

typealias PeerUpdate = (DMEventPeer) -> (DMEventPeer)

struct DMEventPeerPersistenceContexts {
    
    enum ContextKeys: String {
        case reconnect
        case isHost
        case uuid
    }
    
    static let hostDiscovery = [ContextKeys.isHost.rawValue: "true"]
    static let participantReconnect = [ContextKeys.reconnect.rawValue: "true"]
}

enum DMEventPeerPersistenceServiceError: Error {
    case peerCreationFailed
    case fetchingFailed
    case existenceCheckFailed
    case updateFailed(DMEventPeer)
    case deletionFailed(DMEventPeer)
}

protocol DMEventPeerPersistenceServiceType {
    
    func store(peer: DMEventPeer) -> Observable<DMEventPeer>

    func delete(peer: DMEventPeer) throws

    func peerExists(withPeerID peerID: MCPeerID) -> Observable<DMEventPeer?>
    
    func retrieveHost() -> DMEventPeer?
    
    func retrieveSelf() -> DMEventPeer?
    
    func update(peer: DMEventPeer, updateBlock: PeerUpdate) -> Observable<DMEventPeer>

    func peers() -> Observable<Results<DMEventPeer>>
    
}
