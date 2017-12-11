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

struct DMEventPeerPersistenceContexts {
    
    enum ContextKeys: String {
        case reconnect = "reconnect"
        case isHost = "isHost"
    }
    
    static let hostDiscovery = [ContextKeys.isHost.rawValue: "true"]
    static let participantReconnect = [ContextKeys.reconnect.rawValue: "true"]
}

enum DMEventPeerPersistenceServiceError: Error {
    case peerCreationFailed
    case updateFailed(DMEventPeer)
    case deletionFailed(DMEventPeer)
}

protocol DMEventPeerPersistenceServiceType {
    
    @discardableResult
    func store(peer: DMEventPeer) throws -> DMEventPeer
    
    @discardableResult
    func storePeer(withContext: [String: String]?, peerID: MCPeerID) throws -> DMEventPeer
    
    @discardableResult
    func retrieveHost() -> DMEventPeer?

    @discardableResult
    func retrieveSelf() -> DMEventPeer?

    func peers() -> Observable<Results<DMEventPeer>>
    
}
