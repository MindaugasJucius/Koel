//
//  DMUser.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/19/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import CloudKit

enum UserKey: String {
    case currentJoinedEvent
    case fullName
    case recordID
    case pastEvents
}

final class DMUser: NSObject, CKRecordModel, NSCoding {

    let currentJoinedEvent: DMEvent?
    let fullName: String?
    let id: CKRecordID
    let pastEvents: [DMEvent]? // TODO ;]
    
    init(currentJoinedEvent: DMEvent?, fullName: String?, id: CKRecordID, pastEvents: [DMEvent]?) {
        self.currentJoinedEvent = currentJoinedEvent
        self.fullName = fullName
        self.id = id
        self.pastEvents = pastEvents
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(forKey: UserKey.recordID.rawValue) as? CKRecordID else {
            return nil
        }
        let fullName = aDecoder.decodeObject(forKey: UserKey.fullName.rawValue) as? String
        self.init(currentJoinedEvent: nil, fullName: fullName, id: id, pastEvents: nil)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(fullName, forKey: UserKey.fullName.rawValue)
        aCoder.encode(id, forKey: UserKey.recordID.rawValue)
    }
    
    func asCKRecord() -> CKRecord {
        //because Users is a default record type, and it's name can't be changed
        let userRecord = CKRecord(recordType: "Users", recordID: id)
        userRecord[UserKey.fullName] = fullName
        
        if let joinedEventID = currentJoinedEvent?.id {
            userRecord[UserKey.currentJoinedEvent] = CKReference(recordID: joinedEventID, action: .none)
        }
        
        return userRecord
    }
    
    static func from(CKRecord record: CKRecord) -> DMUser {
        let fullName = record[UserKey.fullName] as? String
        let id = record.recordID
        return DMUser(currentJoinedEvent: nil, fullName: fullName, id: id, pastEvents: nil)
    }

}
