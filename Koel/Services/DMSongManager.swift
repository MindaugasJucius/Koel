//
//  DMSongManager.swift
//  Koel
//
//  Created by Mindaugas Jucius on 18/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import CloudKit

class DMSongManager: NSObject, DMManager {

    let event: CKRecord
    
    init(withEvent event: CKRecord) {
        self.event = event
        super.init()
    }
    
    func fetchSongs(forEventID eventToMatchID: CKRecordID? = nil, completion: @escaping FetchSuccessMultipleRecords, failure: @escaping FetchFailure) {
        let eventID = eventToMatchID ?? event.recordID
        
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
    
    func saveSongCreationSubscription(forEvent eventWithoutSubscription: CKRecord? = nil) {
        let eventRecord = eventWithoutSubscription ?? event
        
        guard !DMUserDefaultsHelper.SongCreationSubsriptionExists else {
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
    
    func save(aSong song: DMSong, completion: @escaping FetchSuccessSingleRecord) {
        cloudKitContainer.publicCloudDatabase.save(
            song.asCKRecord(),
            completionHandler: { songRecord, error in
                if let song = songRecord {
                    print("INSERTED A SONG. ID: \(song.recordID.recordName)")
                }
        }
        )
    }
    
    func fetchASong(withSongRecordID songID: CKRecordID, completion: @escaping FetchSuccessSingleRecord, failure: @escaping FetchFailure) {
        let fetchSongOperation = CKFetchRecordsOperation(recordIDs: [songID])
        fetchSongOperation.queuePriority = .veryHigh
        fetchSongOperation.qualityOfService = .userInitiated
        
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
    
}
