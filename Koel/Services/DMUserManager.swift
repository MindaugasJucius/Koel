//
//  DMUserManager.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/14/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import CloudKit

class DMUserManager: NSObject, DMManager {
    
    private let eventManager = DMEventManager()
    
    /// Joins a specified event.
    /// Currently a user can only join one event at a time.
    /// Event joining is accomplished by setting User record field currentJoinedEvent as a reference
    /// to passed in DMEvent's id. DMEvent should previously be saved to CloudKit (otherwise event entity won't have an ID).
    ///
    /// - Parameter event: an Event to join
    func join(event: DMEvent, joined: @escaping (DMUser) -> (), failure: @escaping FetchFailure) {
        guard let user = DMUserDefaultsHelper.CloudKitUserRecord else {
            fatalError("User must be present to join an event.")
        }
        
        let userToJoinAnEvent = DMUser(currentJoinedEvent: event, fullName: user.fullName, identifier: user.identifier, pastEvents: user.pastEvents)
        
        let modifyUserOperation = CKModifyRecordsOperation(recordsToSave: [userToJoinAnEvent.asCKRecord()], recordIDsToDelete: nil)
        
        modifyUserOperation.savePolicy = .allKeys
        modifyUserOperation.qualityOfService = .userInitiated
        modifyUserOperation.modifyRecordsCompletionBlock = { [unowned self] savedRecords, _, error in
            if let error = error {
                failure(error)
            }
            
            guard let joinedUser = savedRecords?.first else {
                fatalError("This shouldn't be empty")
            }
            self.eventManager.saveSongCreationSubscription(forEvent: event)
            let eventRecord = event.asCKRecord()
            DMUserDefaultsHelper.set(anyEntity: eventRecord, forKey: DMUserDefaultsHelper.CurrentEventRecordKey)
            joined(DMUser.from(CKRecord: joinedUser))
        }

        cloudKitContainer.publicCloudDatabase.add(modifyUserOperation)
        
        // Ask user for full name and update user model if access is gained
                    
//        CKContainer.default().requestApplicationPermission(.userDiscoverability) { status, error in
//            guard status == .granted, error == nil else {
//                // error handling voodoo
//                return
//            }
//
//            CKContainer.default().discoverUserIdentity(withUserRecordID: user.id) { identity, error in
//                guard let components = identity?.nameComponents, error == nil else {
//                    // more error handling magic
//                    return
//                }
//
//                DispatchQueue.main.async {
//                    let fullName = PersonNameComponentsFormatter().string(from: components)
//                    print("The user's full name is \(fullName)")
//                }
//            }
//        }
        
        
    }
    
    
    /// Fetch currently logged in iCloud user's ID
    ///
    /// - Parameters:
    ///   - success: invoked with the record ID of user's record in case of success
    ///   - failure: invoked in case of a failure
    private func fetchCloudKitCurrentUserId(success: @escaping (CKRecordID) -> (), failure: @escaping FetchFailure) {
        cloudKitContainer.fetchUserRecordID { recordId, error in
            if let error = error {
                failure(error)
            } else if let userIdRecord = recordId {
                success(userIdRecord)
            }
        }
    }
    
    
    /// Fetches a record from Users table that matches current users record ID.
    /// This method combines functionality of two calls to CloudKit:
    /// 1. Fetch current users ID
    /// 2. Fetch record based on ID
    ///
    /// - Parameters:
    ///   - success: success closure is passed a User record
    ///   - failure: error handling closure
    func fetchFullCurrentUserRecord(success: @escaping (DMUser) -> (), failure: @escaping FetchFailure) {
        
        let fetchFullUserRecord = { (userRecordID: CKRecordID) in
            self.cloudKitContainer.publicCloudDatabase.fetch(withRecordID: userRecordID) { fetchedRecord, error in
                if let error = error {
                    failure(error)
                } else if let userRecord = fetchedRecord {
                    let user = DMUser.from(CKRecord: userRecord)
                    DMUserDefaultsHelper.set(anyEntity: user, forKey: DMUserDefaultsHelper.CloudKitUserKey)
                    success(user)
                }
            }
        }
        
        fetchCloudKitCurrentUserId(
            success: { userRecordID in
                fetchFullUserRecord(userRecordID)
            },
            failure: { error in
                failure(error)
            }
        )
    }
    
}
