//
//  DMSongManager.swift
//  Koel
//
//  Created by Mindaugas Jucius on 18/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import CloudKit

typealias FetchSuccessSong = (DMSong) -> ()

class DMSongManager: NSObject, DMManager {
    
    let event: DMEvent
    
    init(withEvent event: DMEvent) {
        self.event = event
        super.init()
    }
    
    func fetchSongs(forEventID eventToMatchID: CKRecordID? = nil, completion: @escaping ([DMSong]) -> (), failure: @escaping KoelFailure) {
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
                completion(songs.map({ DMSong.from(CKRecord: $0) }))
            }
        }
        
        cloudKitContainer.publicCloudDatabase.add(queryOperation)
    }
        
    func save(aSong song: DMSong, completion: @escaping FetchSuccessSong, failure: @escaping KoelFailure) {
        cloudKitContainer.publicCloudDatabase.save(
            song.asCKRecord(),
            completionHandler: { [unowned self] songRecord, error in
                if let savedSongRecord = songRecord {
                    completion(DMSong.from(CKRecord: savedSongRecord))
                    print("INSERTED A SONG. ID: \(savedSongRecord.recordID.recordName)")
                } else if let error = error {
                    self.retryCloudKitOperationIfPossible(with: error, block: {
                            self.save(aSong: song, completion: completion, failure: failure)
                        }
                    )
                    failure(error)
                }
            }
        )
    }
    
    func fetchASong(withSongRecordID songID: CKRecordID, completion: @escaping (DMSong) -> (), failure: @escaping KoelFailure) {
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
            completion(DMSong.from(CKRecord: songRecord))
        }
        
        cloudKitContainer.publicCloudDatabase.add(fetchSongOperation)
    }
    
}
