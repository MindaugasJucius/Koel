//
//  DMEventManager.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/12/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import CloudKit

protocol DMManager {
    var cloudKitContainer: CKContainer { get }
}

extension DMManager {
    
    var cloudKitContainer: CKContainer {
        return CKContainer.default()
    }
    
}

private let serverChangeTokenKey = "ckServerChangeToken"

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
    
    func save(aSong song: DMSong, completion: @escaping () -> ()) {
        cloudKitContainer.publicCloudDatabase.save(
            song.asCKRecord(),
            completionHandler: { songRecord, error in
                if let song = songRecord {
                    print("INSERTED A SONG. ID: \(song.recordID.recordName)")
                }
            }
        )
    }
    
    func fetchSongs(forEventID eventID: CKRecordID, completion: @escaping ([CKRecord]) -> (), failure: @escaping (Error) -> ()) {
        let recordToMatch = CKReference(recordID: eventID, action: .deleteSelf)
        let predicate = NSPredicate(format: "parentEvent == %@", recordToMatch)

        let query = CKQuery(recordType: String(describing: DMSong.self), predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.queuePriority = .veryHigh
        queryOperation.qualityOfService = .userInitiated
        queryOperation.resultsLimit = 750

        var songs: [CKRecord] = []
        
        queryOperation.recordFetchedBlock = { record in
            songs.append(record)
        }
        
        queryOperation.queryCompletionBlock = { cursor, error in
            if let error = error {
                failure(error)
            } else {
                completion(songs)
            }
        }
        
        cloudKitContainer.publicCloudDatabase.add(queryOperation)
    }
    
    func saveSongCreationSubscription() {
        guard !DMUserDefaultsHelper.SongCreationSubsriptionExists else {
            return
        }
        
        guard let eventRecord = DMUserDefaultsHelper.CurrentEventRecord else {
            return
        }
    
        let predicate = NSPredicate(format: "parentEvent = %@", CKReference(recordID: eventRecord.recordID, action: .none))
        let subscription = CKQuerySubscription(
            recordType: String(describing: DMSong.self),
            predicate: predicate,
            subscriptionID: DMEventManager.SongCreationSubscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let notificationInfo = CKNotificationInfo()
        //notificationInfo.shouldSendContentAvailable = true
        notificationInfo.alertBody = "New song"
        notificationInfo.soundName = "default"
        subscription.notificationInfo = notificationInfo
        
        cloudKitContainer.publicCloudDatabase.save(subscription) { subscription, error in
            if let error = error {
                print("error while saving subscription \(error.localizedDescription)")
                return
            }
            print("SAVED SONG CREATION SUBSCRIPTION.")
            UserDefaults.standard.set(true, forKey: DMUserDefaultsHelper.SongCreationSubsriptionExistsKey)
        }
    }
    

//    public func handleNotification() {
//        // Use the ChangeToken to fetch only whatever changes have occurred since the last
//        // time we asked, since intermediate push notifications might have been dropped.
//        let zoneID = CKRecordZoneID(zoneName: "_defaultZone", ownerName: "_ddf5147894f54505e00677fbaa1ee3ed")
//        var changeToken: CKServerChangeToken? = nil
//        let changeTokenData = UserDefaults.standard.data(forKey: serverChangeTokenKey)
//        if changeTokenData != nil {
//            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData!) as! CKServerChangeToken?
//        }
//        let options = CKFetchRecordZoneChangesOptions()
//        options.previousServerChangeToken = changeToken
//        let optionsMap = [zoneID: options]
//
//        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: optionsMap)
//        operation.fetchAllChanges = true
//        operation.recordChangedBlock = { record in
//            print(record)
//            //self.delegate?.cloudKitNoteRecordChanged(record: record)
//        }
//        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changeToken, data in
//            guard let changeToken = changeToken else {
//                return
//            }
//
//            let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
//            UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
//        }
//        operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
//            guard error == nil else {
//                return
//            }
//            guard let changeToken = changeToken else {
//                return
//            }
//
//            let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
//            UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
//        }
//        operation.fetchRecordZoneChangesCompletionBlock = { error in
//            guard error == nil else {
//                return
//            }
//        }
//        operation.qualityOfService = .utility
//
//        cloudKitContainer.publicCloudDatabase.add(operation)
//    }
    
}
