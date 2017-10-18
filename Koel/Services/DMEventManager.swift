//
//  DMEventManager.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/12/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import CloudKit

protocol DMManager {
    typealias FetchSuccessSingleRecord = (CKRecord) -> ()
    typealias FetchSuccessMultipleRecords = ([CKRecord]) -> ()
    typealias FetchFailure = (Error) -> ()
    
    var cloudKitContainer: CKContainer { get }
}

extension DMManager {
    
    var cloudKitContainer: CKContainer {
        return CKContainer.default()
    }
    
}

class DMEventManager: NSObject, DMManager {

    static let SongCreationSubscriptionID = "Event-Song-Created"

    let userManager: DMUserManager
    
    init(withUserManager userManager: DMUserManager = DMUserManager()) {
        self.userManager = userManager
    }
    
    func createEvent() {

        let saveEvent: (String) -> () = { userId in
            let event = DMEvent(code: "0101010", name: "party", eventHasFinished: false)
            self.cloudKitContainer.publicCloudDatabase.save(
                event.asCKRecord(),
                completionHandler: { record, error in
                    guard let eventRecord = record else {
                        print(error as Any)
                        return
                    }
                    print("CREATED EVENT. ID: \(eventRecord.recordID.recordName)")
                    DMUserDefaultsHelper.set(
                        CKRecord: eventRecord,
                        forKey: DMUserDefaultsHelper.CurrentEventRecordKey
                    )
                    print("STORED EVENT TO USER DEFAULTS. ID: \(eventRecord.recordID.recordName)")
                    self.saveSongCreationSubscription()
                }
            )
        }

        if let userId = DMUserDefaultsHelper.CloudKitUserID {
            saveEvent(userId)
        } else {
            userManager.fetchCloudKitCurrentUserId(
                success: { userId in
                    saveEvent(userId)
                },
                failure: nil
            )
        }
    }

}
