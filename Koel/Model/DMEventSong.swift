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
        case addedByUUID
        case upvotedByUUIDs
        case played
        case upvoteCount
        case uuid
        case spotifyURI
    }
    
    dynamic var uuid = NSUUID().uuidString
    dynamic var title: String = ""
    dynamic var spotifyURI: String = ""
    dynamic var added: Date? = nil
    dynamic var played: Date? = nil
    dynamic var addedBy: DMEventPeer? = nil
    dynamic var upvoteCount: Int = 0
    dynamic var upvotedBySelfPeer: Bool = false
    
    let upvotees = List<DMEventPeer>()
    
    var addedByUUID: String? = nil
    var upvotedByUUIDs: [String] = []
    
    override class func primaryKey() -> String? {
        return "uuid"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["peerID", "addedByUUID", "upvotedByUUIDs"]
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(added, forKey: .added)
        try container.encode(played, forKey: .played)
        try container.encode(addedBy?.uuid, forKey: .addedByUUID)
        try container.encode(upvoteCount, forKey: .upvoteCount)
        try container.encode(spotifyURI, forKey: .spotifyURI)
        
        var upvoteesPeerIDDataArray = container.nestedUnkeyedContainer(forKey: .upvotedByUUIDs)
        try upvotees
            .map { $0.uuid }
            .forEach { peerUUID in
            try upvoteesPeerIDDataArray.encode(peerUUID)
        }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uuid = try container.decode(String.self, forKey: .uuid)
        let title = try container.decode(String.self, forKey: .title)
        let added = try container.decode(Date.self, forKey: .added)
        let played = try container.decodeIfPresent(Date.self, forKey: .played)
        let addedByUUID = try container.decodeIfPresent(String.self, forKey: .addedByUUID)
        let upvoteCount = try container.decode(Int.self, forKey: .upvoteCount)
        let spotifyURI = try container.decode(String.self, forKey: .spotifyURI)
        
        var upvoteesPeerUUIDsContainer = try container.nestedUnkeyedContainer(forKey: .upvotedByUUIDs)
        var upvoteesPeerUUIDs: [String] = []
        
        while !upvoteesPeerUUIDsContainer.isAtEnd {
            let upvoteeUUID = try upvoteesPeerUUIDsContainer.decode(String.self)
            upvoteesPeerUUIDs.append(upvoteeUUID)
        }
        
        super.init()
        self.uuid = uuid
        self.title = title
        self.added = added
        self.played = played
        self.upvoteCount = upvoteCount
        self.upvotedByUUIDs = upvoteesPeerUUIDs
        self.addedByUUID = addedByUUID
        self.spotifyURI = spotifyURI
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
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let anotherSong = object as? DMEventSong else {
            return false
        }
        return uuid == anotherSong.uuid && upvoteCount == anotherSong.upvoteCount
    }
    
}

//func == (lhs: DMEventSong, rhs: DMEventSong) -> Bool {
//    // Here you should compare all the values you want to trigger reload of the cell
//    // If `id` is changed cell will be removed and inserted (because `id` is our identity)
//    // If `data` is changed cell will be reloaded
//    return lhs.uuid == rhs.uuid && lhs.upvoteCount == rhs.upvoteCount
//}

extension DMEventSong: IdentifiableType {
    var identity: String {
        return self.isInvalidated ? "" : uuid
    }
}
