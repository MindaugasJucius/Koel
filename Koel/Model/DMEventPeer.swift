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
}

class DMEventPeer: NSObject, NSCoding {
    
    var fullName: String?
    let peerID: MCPeerID
    private let uuid: String
    
    var peerDeviceDisplayName: String {
        return peerID.displayName
    }
    
    init(fullName: String? = nil, peerID: MCPeerID) {
        self.fullName = fullName
        self.peerID = peerID
        self.uuid = UUID.init().uuidString
    }
    
    convenience init(withContext context: [String: String]?, peerID: MCPeerID)
    {
        guard let contextDict = context,
         let fullName = contextDict[Peer.fullName.rawValue] else {
            self.init(fullName: .none, peerID: peerID)
            return
        }
        self.init(fullName: fullName, peerID: peerID)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(fullName, forKey: Peer.fullName.rawValue)
        aCoder.encode(peerID, forKey: Peer.peerID.rawValue)
        aCoder.encode(uuid, forKey: Peer.uuid.rawValue)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.fullName = aDecoder.decodeObject(forKey: Peer.fullName.rawValue) as? String
        guard let peerID = aDecoder.decodeObject(forKey: Peer.peerID.rawValue) as? MCPeerID,
            let uuid = aDecoder.decodeObject(forKey: Peer.uuid.rawValue) as? String else {
            fatalError("failed to deserialize")
        }
        self.peerID = peerID
        self.uuid = uuid
    }
    
}

extension DMEventPeer: IdentifiableType {
    var identity: String {
        return uuid
    }
}
