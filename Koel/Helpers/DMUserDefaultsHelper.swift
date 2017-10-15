//
//  DMUserDefaultsHelper.swift
//  Koel
//
//  Created by Mindaugas Jucius on 13/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import CloudKit

class DMUserDefaultsHelper: NSObject {

    static let CloudKitUserIDKey = "CloudKitUserID"
    static let CurrentEventRecordKey = "CurrentEventRecord"
    static let SongCreationSubsriptionExistsKey = "SongCreationSubsriptionExists"
    
    static func set(value: Any, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static func set(CKRecord record: CKRecord, forKey key: String) {
        let recordData = NSKeyedArchiver.archivedData(withRootObject: record)
        DMUserDefaultsHelper.set(value: recordData, forKey: key)
    }
    
    private static func getCKRecord(withKey key: String) -> CKRecord? {
        guard let recordData = UserDefaults.standard.object(forKey: key) as? Data else {
            return nil
        }
        
        return NSKeyedUnarchiver.unarchiveObject(with: recordData) as? CKRecord
    }
    
    static var CloudKitUserID: String? {
        return UserDefaults.standard.string(forKey: CloudKitUserIDKey)
    }
    
    static var CurrentEventRecord: CKRecord? {
        return DMUserDefaultsHelper.getCKRecord(withKey: CurrentEventRecordKey)
    }
    
    static var SongCreationSubsriptionExists: Bool {
        return UserDefaults.standard.bool(forKey: SongCreationSubsriptionExistsKey)
    }

}
