//
//  DMEventManager.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/12/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import CloudKit

protocol CKRecordModel {
    func asCKRecord() -> CKRecord
}

class DMEventManager: NSObject {

    private let cloudKitContainer = CKContainer.default()
    
    func createEvent() {

        let saveEvent: (String) -> () = { userId in
            let event = DMEvent(creatorId: userId, code: "0101010", name: "party", queue: ["song1", "song2"])
            self.cloudKitContainer.publicCloudDatabase.save(
                event.asCKRecord(),
                completionHandler: { record, error in
                    print(record)
                    print(error)
                }
            )
        }

        if let userId = DMUserDefaultsHelper.iCloudUserID {
            saveEvent(userId)
        } else {
            fetchiCloudCurrentUserId(
                success: { userId in
                    saveEvent(userId)
                },
                failure: nil
            )
        }
    
    }
    
    func fetchiCloudCurrentUserId(success: ((String) -> ())? = nil, failure: ((Error) -> ())? = nil) {
        cloudKitContainer.fetchUserRecordID { recordId, error in
            if let error = error {
                failure?(error)
                print(error.localizedDescription)
            } else if let userIdRecord = recordId {
                let userId = userIdRecord.recordName
                DMUserDefaultsHelper.set(value: userId, forKey: DMUserDefaultsHelper.iCloudUserIDKey)
                success?(userId)
            }
        }
    }
    
}
