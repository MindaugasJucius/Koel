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
    
    fileprivate static let recordName = String(describing: DMEvent.self)
    
    let code: String
    let name: String
    var eventHasFinished: Bool
    var id: CKRecordID
    
    init(code: String, name: String, eventHasFinished: Bool, id: CKRecordID = CKRecordID(recordName: recordName)) {
        self.code = code
        self.name = name
        self.eventHasFinished = eventHasFinished
        self.id = id
    }
    
    func asCKRecord() -> CKRecord {
        let record = CKRecord(recordType: DMEvent.recordName, recordID: id)
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
            name: name,
            eventHasFinished:
            finished,
            id: id
        )

    }
    
}
