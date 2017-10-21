//
//  DMEvent.swift
//  Koel
//
//  Created by Mindaugas Jucius on 13/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import CloudKit

protocol CKRecordModel {
    func asCKRecord() -> CKRecord
    static func from(CKRecord: CKRecord) -> Self
}

enum EventKey: String {
    case code
    case name
    case recordID
    case eventHasFinished
}

struct DMEvent: CKRecordModel {
    
    let code: String
    var id: CKRecordID?
    var name: String
    var eventHasFinished: Bool
    
    func asCKRecord() -> CKRecord {
        let record: CKRecord
        
        if let recordID = id {
            record = CKRecord(recordType: String(describing: DMEvent.self), recordID: recordID)
        } else {
            record = CKRecord(recordType: String(describing: DMEvent.self))
        }
        
        record[EventKey.code] = code
        record[EventKey.name] = name
        record[EventKey.eventHasFinished] = eventHasFinished

        return record
    }
    
    static func from(CKRecord record: CKRecord) -> DMEvent {
        
        guard let code = record[EventKey.code] as? String,
            let id = record[EventKey.recordID] as? CKRecordID,
            let name = record[EventKey.name] as? String,
            let finished = record[EventKey.eventHasFinished] as? Bool else
        {
            fatalError("Couldn't unpack DMEvent from CKRecord")
        }
        
        return DMEvent(
            code: code,
            id: id,
            name: name,
            eventHasFinished: finished
        )
    }
    
}
