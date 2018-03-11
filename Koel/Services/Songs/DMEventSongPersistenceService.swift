//
//  File.swift
//  Koel
//
//  Created by Mindaugas Jucius on 08/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import RxRealm
import MultipeerConnectivity

struct DMEventSongPersistenceService: DMEventSongPersistenceServiceType {
    
    private let concurrentScheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS.background)
    
    private func withRealm<T: ThreadConfined>(operation: String, error: Error, action: @escaping (Realm) throws -> T) -> Observable<T> {
        return Observable<ThreadSafeReference<T>>
            .create { observer -> Disposable in
                do {
                    let realm = try Realm()
                    let result = try action(realm)
                    observer.onNext(ThreadSafeReference(to: result))
                } catch {
                    observer.onError(error)
                }
                observer.onCompleted()
                return Disposables.create()
            }
            .subscribeOn(concurrentScheduler)
            .observeOn(MainScheduler.instance)
            .flatMap { threadSafePlayedSongReference -> Observable<T> in
                return Realm.objectOnMainSchedulerObservable(
                    fromReference: threadSafePlayedSongReference,
                    errorOnFailure: error
            )
        }
    }

    @discardableResult
    func store(song: DMEventSong) -> Observable<DMEventSong> {
        let result = withRealm(
            operation: "creating",
            error: DMEventSongPersistenceServiceError.creationFailed) { realm -> DMEventSong in
                try realm.write {
                    song.id = (realm.objects(DMEventSong.self).max(ofProperty: "id") ?? 0) + 1
                    
                    // Parse peer which added song that's being persisted
                    if let addedPeerUUID = song.addedByUUID {
                        let uuidPredicate = NSPredicate(format: "uuid = %@", addedPeerUUID)
                        song.addedBy = realm.objects(DMEventPeer.self).filter(uuidPredicate).first
                    }
                    
                    // Parse peers who upvoted song that's being persisted
                    if let upvoteesUUIDs = song.upvotedByUUIDs {
                        let uuidPredicate = NSPredicate(format: "uuid IN %@", upvoteesUUIDs)
                        let upvotees = realm.objects(DMEventPeer.self).filter(uuidPredicate)
                        song.upvotees.append(objectsIn: upvotees)
                        song.upvoteCount = upvoteesUUIDs.count
                    }
                    
                    realm.add(song, update: true)
                }
                return song
            }
    
        return result
    }
    
    @discardableResult
    func markAsPlayed(song: DMEventSong) -> Observable<DMEventSong> {
        let result = withRealm(
            operation: "marking as played",
            error: DMEventSongPersistenceServiceError.toggleFailed(song)) { realm -> DMEventSong in
                try realm.write {
                    if song.played == nil {
                        song.played = Date()
                    }
                }
                return song
            }

        return result
    }
    
    @discardableResult
    func upvote(song: DMEventSong, forUser user: DMEventPeer) -> Observable<DMEventSong> {
        let result = withRealm(
            operation: "upvoting",
            error: DMEventSongPersistenceServiceError.upvoteFailed(song)) { realm -> DMEventSong in
                try realm.write {
                    song.upvotees.append(user)
                    song.upvoteCount = song.upvoteCount + 1
                }
                return song
            }
        return result
    }
    
    func songs() -> Observable<Results<DMEventSong>> {
        let result = withRealm(
            operation: "getting all songs",
            error: DMEventSongPersistenceServiceError.fetchingSongsFailed) { realm -> Results<DMEventSong> in
                let songs = realm.objects(DMEventSong.self)
                return songs
            }
            .flatMap { threadSafeSongs -> Observable<Results<DMEventSong>> in
                return Observable.collection(from: threadSafeSongs)
            }
        return result
    }

}
