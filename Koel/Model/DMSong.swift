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
    case recordID
}

struct DMSong: CKRecordModel {

    static let notificationSongIDKey = "songID"
    static let notificationReasonSongKey = "songIDNotificationReason"
    
    let hasBeenPlayed: Bool
    var id: CKRecordID?
    let eventID: CKRecordID
    let spotifySongID: String
    
    func asCKRecord() -> CKRecord {
        let record: CKRecord
        let recordType = String(describing: DMSong.self)
        if let recordID = id {
            record = CKRecord(recordType: recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: recordType)
        }
        record[SongKey.hasBeenPlayed] = hasBeenPlayed
        record[SongKey.parentEvent] = CKReference(recordID: eventID, action: .deleteSelf)
        record[SongKey.spotifySongID] = spotifySongID
        return record
    }
    
    static func from(CKRecord record: CKRecord) -> DMSong {
        
        guard let alreadyPlayed = record[SongKey.hasBeenPlayed] as? Bool,
            let eventID = record[SongKey.parentEvent] as? CKRecordID,
            let spotifySongID = record[SongKey.spotifySongID] as? String else {
                fatalError("Failed to unpack DMSong from CKRecord")
        }
        
        return DMSong(
            hasBeenPlayed: alreadyPlayed,
            id: record.recordID,
            eventID: eventID,
            spotifySongID: spotifySongID
        )
    }
}
