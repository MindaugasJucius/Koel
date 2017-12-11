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
    
    var peerID: MCPeerID? = nil {
        didSet {
            guard let `peerID` = peerID else {
                return
            }
            //peerIDData = NSKeyedArchiver.archivedData(withRootObject: peerID)
        }
    }
    
    //dynamic var peerIDData: Data? = nil
    //peerID = NSKeyedUnarchiver.unarchiveObject(with: peerIDData) as? MCPeerID
    
    override static func ignoredProperties() -> [String] {
        return ["peerID"]
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
//    var peerID: MCPeerID {
//        get {
//            guard let data = peerIDData else { return <#return value#> }
//            NSKeyedUnarchiver.unarchiveObject(with: peerIDData) as? DMEventPeer
//        }
//        set {
//            peerIDData = NSKeyedArchiver.archivedData(withRootObject: newValue)
//        }
//    }
    
//    var connected: Bool {
//        return isSelf ? true : isConnected
//    }
    
//    var peerDeviceDisplayName: String {
//        return peerID.displayName
//    }
    
//    init(fullName: String? = nil, peerID: MCPeerID, isHost: Bool = false, isConnected: Bool = false) {
//        self.fullName = fullName
//        self.peerID = peerID
//        self.isHost = isHost
//        self.isConnected = isConnected
//        self.uuid = UUID.init().uuidString
//    }
    
//    convenience init(withContext context: [String: String]?, peerID: MCPeerID)
//    {
//        guard let contextDict = context else {
//            self.init(peerID: peerID)
//            return
//        }
//        let fullName = contextDict[Peer.fullName.rawValue]
//        let isHost = contextDict[Peer.isHost.rawValue]
//        self.init(fullName: fullName, peerID: peerID, isHost: isHost != .none)
//    }
    
//    func encode(with aCoder: NSCoder) {
//        aCoder.encode(fullName, forKey: Peer.fullName.rawValue)
//        aCoder.encode(peerID, forKey: Peer.peerID.rawValue)
//        aCoder.encode(uuid, forKey: Peer.uuid.rawValue)
//        aCoder.encode(isHost, forKey: Peer.isHost.rawValue)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        self.fullName = aDecoder.decodeObject(forKey: Peer.fullName.rawValue) as? String
//        guard let peerID = aDecoder.decodeObject(forKey: Peer.peerID.rawValue) as? MCPeerID,
//            let uuid = aDecoder.decodeObject(forKey: Peer.uuid.rawValue) as? String else {
//            fatalError("failed to deserialize")
//        }
//        self.isConnected = false
//        self.peerID = peerID
//        self.uuid = uuid
//        self.isHost = aDecoder.decodeBool(forKey: Peer.isHost.rawValue)
//    }
    
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
