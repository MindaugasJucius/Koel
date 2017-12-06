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

enum Peer: String {
    case fullName
    case peerID
    case uuid
    case isHost
}

typealias EventPeerSection = AnimatableSectionModel<String, DMEventPeer>

class DMEventPeer: NSObject, NSCoding {
    
    var fullName: String?
    let isHost: Bool
    var isConnected: Bool
    let peerID: MCPeerID
    private let uuid: String
    
    var peerDeviceDisplayName: String {
        return peerID.displayName
    }
    
    init(fullName: String? = nil, peerID: MCPeerID, isHost: Bool = false, isConnected: Bool = false) {
        self.fullName = fullName
        self.peerID = peerID
        self.isHost = isHost
        self.isConnected = isConnected
        self.uuid = UUID.init().uuidString
    }
    
    convenience init(withContext context: [String: String]?, peerID: MCPeerID)
    {
        guard let contextDict = context else {
            self.init(peerID: peerID)
            return
        }
        let fullName = contextDict[Peer.fullName.rawValue]
        let isHost = contextDict[Peer.isHost.rawValue]
        self.init(fullName: fullName, peerID: peerID, isHost: isHost != .none)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(fullName, forKey: Peer.fullName.rawValue)
        aCoder.encode(peerID, forKey: Peer.peerID.rawValue)
        aCoder.encode(uuid, forKey: Peer.uuid.rawValue)
        aCoder.encode(isHost, forKey: Peer.isHost.rawValue)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.fullName = aDecoder.decodeObject(forKey: Peer.fullName.rawValue) as? String
        guard let peerID = aDecoder.decodeObject(forKey: Peer.peerID.rawValue) as? MCPeerID,
            let uuid = aDecoder.decodeObject(forKey: Peer.uuid.rawValue) as? String else {
            fatalError("failed to deserialize")
        }
        self.isConnected = false
        self.peerID = peerID
        self.uuid = uuid
        self.isHost = aDecoder.decodeBool(forKey: Peer.isHost.rawValue)
    }
    
    //to be used with non failable Units
    static var empty: DMEventPeer {
        return DMEventPeer(peerID: MCPeerID(displayName: "empty"))
    }
    
}

extension DMEventPeer: IdentifiableType {
    var identity: String {
        return uuid
    }
}

func == (lhs: DMEventPeer, rhs: DMEventPeer) -> Bool {
    return lhs.peerDeviceDisplayName == rhs.peerDeviceDisplayName
        && lhs.isConnected == rhs.isConnected
}
