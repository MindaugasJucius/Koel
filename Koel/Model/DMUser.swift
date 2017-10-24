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
    case identifier
}

final class DMUser: NSObject, NSCoding {

    let currentJoinedEvent: DMEvent?
    let fullName: String?
    let pastEvents: [DMEvent]? // TODO ;]
    
    var identifier: String
    
    init(currentJoinedEvent: DMEvent?, fullName: String?, identifier: String, pastEvents: [DMEvent]?) {
        self.currentJoinedEvent = currentJoinedEvent
        self.fullName = fullName
        self.pastEvents = pastEvents
        self.identifier = identifier
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let identifier = aDecoder.decodeObject(forKey: UserKey.identifier.rawValue) as? String else {
            return nil
        }
        let fullName = aDecoder.decodeObject(forKey: UserKey.fullName.rawValue) as? String
        self.init(currentJoinedEvent: nil, fullName: fullName, identifier: identifier, pastEvents: nil)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(fullName, forKey: UserKey.fullName.rawValue)
        aCoder.encode(identifier, forKey: UserKey.identifier.rawValue)
    }
    
}

extension DMUser: CKRecordModel {
    
    func asCKRecord() -> CKRecord {
        //because Users is a default record type, and it's name can't be changed
        let userRecord = CKRecord(recordType: "Users", recordID: recordID)
        userRecord[UserKey.fullName] = fullName
        userRecord[UserKey.identifier] = identifier
        if let joinedEventID = currentJoinedEvent?.recordID {
            userRecord[UserKey.currentJoinedEvent] = CKReference(recordID: joinedEventID, action: .none)
        }
        
        return userRecord
    }
    
    static func from(CKRecord record: CKRecord) -> DMUser {
        let fullName = record[UserKey.fullName] as? String
        
        return DMUser(
            currentJoinedEvent: nil,
            fullName: fullName,
            identifier: record.recordID.recordName,
            pastEvents: nil
        )
    }
    
}
