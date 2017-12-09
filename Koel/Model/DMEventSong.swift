//
//  DMEventSong.swift
//  Koel
//
//  Created by Mindaugas Jucius on 08/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RealmSwift
import RxDataSources

typealias SongSection = AnimatableSectionModel<String, DMEventSong>

@objcMembers
class DMEventSong: Object {
    
    dynamic var id: Int = 0
    dynamic var title: String = ""
    dynamic var upvoteCount = 0
    
    dynamic var added: Date = Date()
    dynamic var played: Date? = nil
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}

extension DMEventSong: IdentifiableType {
    var identity: Int {
        return self.isInvalidated ? 0 : id
    }
}

//func == (lhs: DMEventSong, rhs: DMEventSong) -> Bool {
//    return lhs.title == rhs.title && lhs.added == lhs.added && lhs.played == lhs.played
//}

