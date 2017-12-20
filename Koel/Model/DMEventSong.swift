//
//  DMEventSong.swift
//  Koel
//
//  Created by Mindaugas Jucius on 08/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import RxDataSources
import RxSwift

typealias SongSection = AnimatableSectionModel<String, DMEventSong>

@objcMembers
class DMEventSong: Object, Codable {
    
    private enum CodingKeys: String, CodingKey {
        case title
        case added
        case addedByPeerID
        case upvotedByPeerIDs
        case played
        case upvoteCount
    }
    
    dynamic var id: Int = 0
    dynamic var title: String = ""
    dynamic var added: Date = Date()
    dynamic var played: Date? = nil
    dynamic var addedBy: DMEventPeer? = nil
    dynamic var upvoteCount: Int = 0
    
    let upvotees = List<DMEventPeer>()
    
    var addedByData: Data? = nil
    var upvotedByData: [Data]? = nil
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["peerID", "addedByData", "upvotedByData"]
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(added, forKey: .added)
        try container.encode(played, forKey: .played)
        try container.encode(addedBy?.peerIDData, forKey: .addedByPeerID)
        try container.encode(upvoteCount, forKey: .upvoteCount)
        
        var upvoteesPeerIDDataArray = container.nestedUnkeyedContainer(forKey: .upvotedByPeerIDs)
        let upvoteesPeerIDData = upvotees.map { $0.peerIDData }
        try upvoteesPeerIDData.forEach { peerIDData in
            try upvoteesPeerIDDataArray.encode(peerIDData)
        }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let title = try container.decode(String.self, forKey: .title)
        let added = try container.decode(Date.self, forKey: .added)
        let played = try container.decodeIfPresent(Date.self, forKey: .played)
        let addedByPeerIDData = try container.decodeIfPresent(Data.self, forKey: .addedByPeerID)
        let upvoteCount = try container.decode(Int.self, forKey: .upvoteCount)
        
        var upvoteesPeerIDDataContainer = try container.nestedUnkeyedContainer(forKey: .upvotedByPeerIDs)
        var upvoteesPeerIDData: [Data] = []
        
        while !upvoteesPeerIDDataContainer.isAtEnd {
            let upvoteeIDData = try upvoteesPeerIDDataContainer.decode(Data.self)
            upvoteesPeerIDData.append(upvoteeIDData)
        }
        
        super.init()
        
        self.title = title
        self.added = added
        self.played = played
        self.upvoteCount = upvoteCount
        self.upvotedByData = upvoteesPeerIDData
        self.addedByData = addedByPeerIDData
    }

    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }

    required init() {
        super.init()
    }

    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
}

extension DMEventSong: IdentifiableType {
    var identity: Int {
        return self.isInvalidated ? 0 : id
    }
}
