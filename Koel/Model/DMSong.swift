//
//  DMSong.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/14/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import CloudKit


enum SongKey: String {
    case hasBeenPlayed
    case parentEvent
    case spotifySongID
}

struct DMSong: CKRecordModel {
    
    let hasBeenPlayed: Bool
    let eventID: CKRecordID
    let spotifySongID: String
    
    func asCKRecord() -> CKRecord {
        let record = CKRecord(recordType: String(describing: DMSong.self))
        record[SongKey.hasBeenPlayed] = hasBeenPlayed
        record[SongKey.parentEvent] = CKReference(recordID: eventID, action: .deleteSelf)
        record[SongKey.spotifySongID] = spotifySongID
        return record
    }
    
}
