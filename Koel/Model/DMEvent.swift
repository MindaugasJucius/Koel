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
}

enum EventKey: String {
    case code
    case name
    case eventHasFinished
}

struct DMEvent: CKRecordModel {
    
    let code: String
    var id: String?
    var name: String
    var eventHasFinished: Bool
    
    func asCKRecord() -> CKRecord {
        let record = CKRecord(recordType: String(describing: DMEvent.self))
        record[EventKey.code] = code
        record[EventKey.name] = name
        record[EventKey.eventHasFinished] = eventHasFinished

        return record
    }
    
}
