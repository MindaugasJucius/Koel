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
    case identifier
    case recordID
}

struct DMSong {

    static let notificationSongIDKey = "songID"
    static let notificationReasonSongKey = "songIDNotificationReason"
    
    let hasBeenPlayed: Bool
    let eventID: CKRecordID
    let spotifySongID: String?
    
    var identifier: String
    var modificationDate: Date?
    
    init(hasBeenPlayed: Bool, identifier: String? = nil, eventID: CKRecordID, spotifySongID: String?, modificationDate: Date? = nil) {
        self.hasBeenPlayed = hasBeenPlayed
        self.identifier = identifier ?? UUID().uuidString
        self.eventID = eventID
        self.spotifySongID = spotifySongID
        self.modificationDate = modificationDate
    }

}

extension DMSong: CKRecordModel {

    func asCKRecord() -> CKRecord {
        let record = CKRecord(recordType: DMSong.recordType, recordID: recordID)
        record[SongKey.hasBeenPlayed] = hasBeenPlayed
        record[SongKey.parentEvent] = CKReference(recordID: eventID, action: .deleteSelf)
        record[SongKey.spotifySongID] = spotifySongID
        record[SongKey.identifier] = identifier
        return record
    }
    
    static func from(CKRecord record: CKRecord) -> DMSong {
        
        guard let eventID = record[SongKey.parentEvent] as? CKReference,
            let identifier = record[EventKey.identifier] as? String else {
                fatalError("Failed to unpack DMSong from CKRecord")
        }
        
        return DMSong(
            hasBeenPlayed: record[SongKey.hasBeenPlayed] as? Bool ?? false,
            identifier: identifier,
            eventID: eventID.recordID,
            spotifySongID: record[SongKey.spotifySongID] as? String,
            modificationDate: record.modificationDate
        )
    }
    
}
