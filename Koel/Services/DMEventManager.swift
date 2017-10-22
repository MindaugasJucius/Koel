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
    
    func retryCloudKitOperationIfPossible(with error: Error?, block: @escaping () -> ()) {
        guard let error = error as? CKError else {
            //slog("CloudKit puked ¯\\_(ツ)_/¯")
            return
        }
        
        guard let retryAfter = error.userInfo[CKErrorRetryAfterKey] as? NSNumber else {
            //slog("CloudKit error: \(error)")
            return
        }
        
        //slog("CloudKit operation error, retrying after \(retryAfter) seconds...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter.doubleValue) {
            block()
        }
    }
    
}

class DMEventManager: NSObject, DMManager {
    
    static let SongCreationSubscriptionID = "Event-Song-Created"
    
    func createEvent() {
        var event = DMEvent(code: "0101010", name: "dank parti", eventHasFinished: false)
        
        self.cloudKitContainer.publicCloudDatabase.save(
            event.asCKRecord(),
            completionHandler: { [unowned self] record, error in
                guard let eventRecord = record else {
                    self.retryCloudKitOperationIfPossible(with: error, block: {
                            self.createEvent()
                        }
                    )
                    print(error as Any)
                    return
                }
                print("CREATED EVENT. ID: \(eventRecord.recordID.recordName)")
                print("Paziuret ar toks pat id kaip UUID")
                print(eventRecord.recordID)
                //event.id = eventRecord.recordID
                DMUserDefaultsHelper.set(
                    anyEntity: eventRecord,
                    forKey: DMUserDefaultsHelper.CurrentEventRecordKey
                )
                print("STORED EVENT TO USER DEFAULTS. ID: \(eventRecord.recordID.recordName)")
                self.saveSongCreationSubscription(forEvent: event)
            }
        )
    }
    
    func fetchAllEvents(success: @escaping ([DMEvent]) -> (), failure: @escaping FetchFailure) {
        let eventQuery = CKQuery(recordType: String(describing: DMEvent.self), predicate: NSPredicate(value: true))
        
        cloudKitContainer.publicCloudDatabase.perform(
            eventQuery,
            inZoneWith: nil,
            completionHandler: { events, error in
                if let error = error {
                    failure(error)
                } else if let events = events {
                    success(events.map { DMEvent.from(CKRecord: $0) })
                }
            }
        )
    }
    
    func saveSongCreationSubscription(forEvent event: DMEvent) {
        
        guard !DMUserDefaultsHelper.SongCreationSubsriptionExists else {
            return
        }
        
        let reference = CKReference(recordID: event.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "parentEvent = %@", reference)
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
