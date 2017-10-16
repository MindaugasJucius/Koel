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
    
    func fetchASong(withSongRecordID songID: CKRecordID, completion: @escaping (CKRecord) -> (), failure: @escaping (Error) -> ()) {
        let fetchSongOperation = CKFetchRecordsOperation(recordIDs: [songID])
        fetchSongOperation.queuePriority = .veryHigh
        fetchSongOperation.qualityOfService = .userInitiated
        
        //fetchSongOperation.perRecordProgressBlock !procentai!
        
        fetchSongOperation.perRecordCompletionBlock = { songRecord, songRecordId, error in
            if let error = error {
                failure(error)
            }
        }
        
        fetchSongOperation.fetchRecordsCompletionBlock = { songsDict, error in
            if let error = error {
                failure(error)
            }
            guard let songRecord = songsDict?[songID] else {
                return
            }
            completion(songRecord)
        }
        
        cloudKitContainer.publicCloudDatabase.add(fetchSongOperation)
    }
    
    func fetchSongs(forEventID eventID: CKRecordID, completion: @escaping ([CKRecord]) -> (), failure: @escaping (Error) -> ()) {
        let recordToMatch = CKReference(recordID: eventID, action: .deleteSelf)
        let predicate = NSPredicate(format: "parentEvent == %@", recordToMatch)

        let query = CKQuery(recordType: String(describing: DMSong.self), predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.queuePriority = .veryHigh
        queryOperation.qualityOfService = .userInitiated

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
//        guard !DMUserDefaultsHelper.SongCreationSubsriptionExists else {
//            return
//        }
        
        guard let eventRecord = DMUserDefaultsHelper.CurrentEventRecord else {
            return
        }
    
        let predicate = NSPredicate(format: "parentEvent = %@", CKReference(recordID: eventRecord.recordID, action: .deleteSelf))
        let subscription = CKQuerySubscription(
            recordType: String(describing: DMSong.self),
            predicate: predicate,
            subscriptionID: DMEventManager.SongCreationSubscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
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

}
