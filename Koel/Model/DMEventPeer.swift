//
//  DMEventPeer.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/2/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import RxDataSources
import RealmSwift

enum Peer: String {
    case fullName
    case peerID
    case uuid
    case isHost
}

typealias EventPeerSection = AnimatableSectionModel<String, DMEventPeer>

@objcMembers
class DMEventPeer: Object {
    
    dynamic var id: Int = 0
    dynamic var fullName: String? = nil
    dynamic var isHost: Bool = false
    dynamic var isConnected: Bool = false
    dynamic var isSelf: Bool = false
    dynamic var peerIDData: Data? = nil
    
    var peerID: MCPeerID? = nil
    
    override static func ignoredProperties() -> [String] {
        return ["peerID"]
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}

extension DMEventPeer {
    
    static func peer(withDisplayName displayName: String, storeAsSelf: Bool = false, storeAsHost: Bool = false) -> DMEventPeer {
        return DMEventPeer.peer(
            withPeerID: MCPeerID(displayName: displayName),
            storeAsSelf: storeAsSelf,
            storeAsHost: storeAsHost
        )
    }
    
    static func peer(withPeerID peerID: MCPeerID, storeAsSelf: Bool = false, storeAsHost: Bool = false) -> DMEventPeer {
        let peer = DMEventPeer()
        peer.peerID = peerID
        peer.isSelf = storeAsSelf
        peer.isHost = storeAsHost
        return peer
    }
    
    static func peer(withPeerID peerID: MCPeerID, context: [String: String]? = nil) -> DMEventPeer {
        guard let contextDict = context else {
            return DMEventPeer.peer(withPeerID: peerID)
        }
        let isHost = contextDict[Peer.isHost.rawValue]
        return DMEventPeer.peer(withPeerID: peerID, storeAsSelf: false, storeAsHost: isHost != .none)
    }
    
}

extension DMEventPeer: IdentifiableType {
    var identity: Int {
        return self.isInvalidated ? 0 : id
    }
}
