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
    
    func createEvent() {
        var event = DMEvent(code: "0101010", id: nil, name: "party", eventHasFinished: false)
        self.cloudKitContainer.publicCloudDatabase.save(
            event.asCKRecord(),
            completionHandler: { record, error in
                guard let eventRecord = record else {
                    print(error as Any)
                    return
                }
                print("CREATED EVENT. ID: \(eventRecord.recordID.recordName)")
                event.id = eventRecord.recordID
                DMUserDefaultsHelper.set(
                    anyEntity: eventRecord,
                    forKey: DMUserDefaultsHelper.CurrentEventRecordKey
                )
                print("STORED EVENT TO USER DEFAULTS. ID: \(eventRecord.recordID.recordName)")
                self.saveSongCreationSubscription(forEvent: event)
            }
        )
    }
    
    func fetchAllEvents(success: @escaping FetchSuccessMultipleRecords, failure: @escaping FetchFailure) {
        let eventQuery = CKQuery(recordType: String(describing: DMEvent.self), predicate: NSPredicate(value: true))
        
        cloudKitContainer.publicCloudDatabase.perform(
            eventQuery,
            inZoneWith: nil,
            completionHandler: { events, error in
                if let error = error {
                    failure(error)
                } else if let events = events {
                    success(events)
                }
            }
        )
    }
    
    func saveSongCreationSubscription(forEvent event: DMEvent) {
        
        guard !DMUserDefaultsHelper.SongCreationSubsriptionExists else {
            return
        }
        
        guard let eventID = event.id else {
            return
        }
        
        let predicate = NSPredicate(format: "parentEvent = %@", CKReference(recordID: eventID, action: .deleteSelf))
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
