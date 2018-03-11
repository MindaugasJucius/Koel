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

typealias EventPeerSection = AnimatableSectionModel<String, DMEventPeer>

@objcMembers
class DMEventPeer: Object, Codable {

    private enum CodingKeys: String, CodingKey {
        case fullName
        case isHost
        case isConnected
        case isSelf
        case peerIDData
    }
    
    dynamic var fullName: String? = nil
    dynamic var isHost: Bool = false
    dynamic var isConnected: Bool = false
    dynamic var isSelf: Bool = false
    dynamic var peerIDData = Data()
    dynamic var uuid = NSUUID().uuidString
    
    var peerID: MCPeerID? = nil
    
    var primaryKeyRef = ""
    
    override static func ignoredProperties() -> [String] {
        return ["peerID"]
    }
    
    override class func primaryKey() -> String? {
        return "uuid"
    }
    
    var discoveryContext: [String:String] {
        var discoveryInfo = ContextKeys.uuid(uuid).dictionary
        
        if isHost {
            discoveryInfo.merge(ContextKeys.isHost.dictionary,
                                uniquingKeysWith: { old, new in new })
        }
        return discoveryInfo
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
    
    static func peer(withPeerID peerID: MCPeerID, storeAsSelf: Bool = false, storeAsHost: Bool = false, uuid: String? = nil) -> DMEventPeer {
        let peer = DMEventPeer()
        peer.peerID = peerID
        peer.isSelf = storeAsSelf
        peer.isHost = storeAsHost
        if let `uuid` = uuid {
            peer.uuid = uuid
        }
        return peer
    }
    
    static func peer(withPeerID peerID: MCPeerID, context: [String: String]? = nil) -> DMEventPeer {
        guard let contextDict = context else {
            return DMEventPeer.peer(withPeerID: peerID, storeAsSelf: false, storeAsHost: false)
        }
        let isHost = contextDict[ContextKeys.isHost.rawValue]
        let uuid = contextDict[ContextKeys.uuid("").rawValue]
        return DMEventPeer.peer(withPeerID: peerID, storeAsSelf: false, storeAsHost: isHost != .none, uuid: uuid)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        return primaryKeyRef == (object as? DMEventPeer)?.primaryKeyRef
    }
    
}



extension DMEventPeer: IdentifiableType {
    var identity: String {
        return self.isInvalidated ? "" : uuid
    }
}
