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

@objc enum DMEventSongState: Int {
    case added
    case playing
    case played
}

@objcMembers
class DMEventSong: Object, Codable, DMEntity {
    
    private enum CodingKeys: String, CodingKey {
        case title
        case artistTitle
        case added
        case addedByUUID
        case upvotedByUUIDs
        case played
        case upvoteCount
        case uuid
        case spotifyURI
        case durationSeconds
    }
    
    dynamic var uuid = NSUUID().uuidString
    dynamic var title: String = ""
    dynamic var artistTitle: String = ""
    dynamic var spotifyURI: String = ""
    dynamic var durationSeconds: TimeInterval = 0
    dynamic var added: Date? = nil
    dynamic var played: Date? = nil
    dynamic var addedBy: DMEventPeer? = nil
    dynamic var upvoteCount: Int = 0
    dynamic var state: DMEventSongState = .added
    
    let upvotees = List<DMEventPeer>()
    
    var addedByUUID: String? = nil
    var upvotedByUUIDs: [String] = []
    var primaryKeyRef = ""
    
    override class func primaryKey() -> String? {
        return "uuid"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["peerID", "addedByUUID", "upvotedByUUIDs", "primaryKeyRef"]
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uuid, forKey: .uuid)
        try container.encode(artistTitle, forKey: .artistTitle)
        try container.encode(title, forKey: .title)
        try container.encode(added, forKey: .added)
        try container.encode(played, forKey: .played)
        try container.encode(addedBy?.uuid, forKey: .addedByUUID)
        try container.encode(upvoteCount, forKey: .upvoteCount)
        try container.encode(spotifyURI, forKey: .spotifyURI)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        
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
        let artistTitle = try container.decode(String.self, forKey: .artistTitle)
        let title = try container.decode(String.self, forKey: .title)
        let added = try container.decode(Date.self, forKey: .added)
        let played = try container.decodeIfPresent(Date.self, forKey: .played)
        let addedByUUID = try container.decodeIfPresent(String.self, forKey: .addedByUUID)
        let upvoteCount = try container.decode(Int.self, forKey: .upvoteCount)
        let spotifyURI = try container.decode(String.self, forKey: .spotifyURI)
        let durationSeconds = try container.decode(TimeInterval.self, forKey: .durationSeconds)
        
        var upvoteesPeerUUIDsContainer = try container.nestedUnkeyedContainer(forKey: .upvotedByUUIDs)
        var upvoteesPeerUUIDs: [String] = []
        
        while !upvoteesPeerUUIDsContainer.isAtEnd {
            let upvoteeUUID = try upvoteesPeerUUIDsContainer.decode(String.self)
            upvoteesPeerUUIDs.append(upvoteeUUID)
        }
        
        super.init()
        self.uuid = uuid
        self.artistTitle = artistTitle
        self.title = title
        self.added = added
        self.played = played
        self.upvoteCount = upvoteCount
        self.upvotedByUUIDs = upvoteesPeerUUIDs
        self.addedByUUID = addedByUUID
        self.spotifyURI = spotifyURI
        self.durationSeconds = durationSeconds
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
        return identity == anotherSong.identity
    }
    
}

extension DMEventSong: IdentifiableType {
    var identity: String {
        return self.isInvalidated ? "" : uuid
    }
}

extension DMEventSong {
    static func from(searchResultSong: DMSearchResultSong, addedBy: DMEventPeer) -> DMEventSong {
        let eventSong = DMEventSong()
        eventSong.spotifyURI = searchResultSong.spotifyURI
        eventSong.artistTitle = searchResultSong.artistName
        eventSong.title = searchResultSong.title
        eventSong.durationSeconds = searchResultSong.durationSeconds
        eventSong.addedByUUID = addedBy.primaryKeyRef
        eventSong.upvotedByUUIDs = [addedBy.primaryKeyRef]
        return eventSong
    }
}
