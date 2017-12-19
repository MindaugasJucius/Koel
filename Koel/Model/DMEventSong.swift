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
class DMEventSong: Object {
    
    dynamic var id: Int = 0
    dynamic var title: String = ""
    dynamic var added: Date = Date()
    dynamic var addedBy: DMEventPeer? = nil
    dynamic var played: Date? = nil
    dynamic var upvoteCount: Int = 0 // can only observe value changes which are fetched from a Realm
    
    let upvotees = List<DMEventPeer>()

    override class func primaryKey() -> String? {
        return "id"
    }
    
}

extension DMEventSong: IdentifiableType {
    var identity: Int {
        return self.isInvalidated ? 0 : id
    }
}
