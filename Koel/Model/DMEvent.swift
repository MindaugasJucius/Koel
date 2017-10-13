//
//  DMEvent.swift
//  Koel
//
//  Created by Mindaugas Jucius on 13/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import CloudKit

enum EventKey: String {
    case creatorId
    case code
    case name
    case queue
}

struct DMEvent: CKRecordModel {

    let creatorId: String
    let code: String
    var name: String
    var queue: [String]
    
    func asCKRecord() -> CKRecord {
        let record = CKRecord(recordType: String(describing: DMEvent.self))
        record[.creatorId] = creatorId
        record[.code] = code
        record[.name] = name
        record[.queue] = queue
        return record
    }
    
}

extension CKRecord {
    
    subscript(key: EventKey) -> Any? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue as? CKRecordValue
        }
    }
    
}
