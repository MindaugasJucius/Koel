//
//  CKRecordModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 22/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import CloudKit

protocol CKRecordModel {
    
    static var recordType: String {
        get
    }
    
    var identifier: String {
        get
    }
    
    var recordID: CKRecordID {
        get
    }
    
    func asCKRecord() -> CKRecord
    static func from(CKRecord: CKRecord) -> Self
    
}

extension CKRecordModel {
    
    static var recordType: String {
        return String(describing: Self.self)
    }
    
    var recordID: CKRecordID {
        return CKRecordID(recordName: identifier)
    }
    
}
