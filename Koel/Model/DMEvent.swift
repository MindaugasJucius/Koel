//
//  DMEvent.swift
//  Koel
//
//  Created by Mindaugas Jucius on 13/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import CloudKit

enum EventKey: String {
    case code
    case name
    case identifier
    case eventHasFinished
}

struct DMEvent {
    
    let code: String
    let name: String
    
    var eventHasFinished: Bool
    var identifier: String
    
    init(code: String, name: String, eventHasFinished: Bool, identifier: String? = nil) {
        self.code = code
        self.name = name
        self.eventHasFinished = eventHasFinished
        self.identifier = identifier ?? UUID().uuidString
    }
    
}

extension DMEvent: CKRecordModel {
    
    func asCKRecord() -> CKRecord {
        let record = CKRecord(recordType: DMEvent.recordType, recordID: recordID)
        record[EventKey.code] = code
        record[EventKey.name] = name
        record[EventKey.eventHasFinished] = eventHasFinished
        return record
    }
    
    static func from(CKRecord record: CKRecord) -> DMEvent {
        
        guard let code = record[EventKey.code] as? String,
            let identifier = record[EventKey.identifier] as? String,
            let name = record[EventKey.name] as? String,
            let finished = record[EventKey.eventHasFinished] as? Bool else
        {
            fatalError("Couldn't unpack DMEvent from CKRecord")
        }
        
        return DMEvent(
            code: code,
            name: name,
            eventHasFinished: finished,
            identifier: identifier
        )
        
    }
    
}
