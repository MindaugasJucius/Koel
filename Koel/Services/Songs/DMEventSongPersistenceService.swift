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

private let songPersistenceScheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS.background)

struct DMEventSongPersistenceService: DMEventSongPersistenceServiceType {

    @discardableResult
    func store(song: DMEventSong) -> Observable<DMEventSong> {
        let result = Realm.withRealm(
            operation: "persisting a song",
            error: DMEventSongPersistenceServiceError.creationFailed,
            scheduler: songPersistenceScheduler) { realm -> DMEventSong in
                try realm.write {
                    song.id = (realm.objects(DMEventSong.self).max(ofProperty: "id") ?? 0) + 1
                    
                    // Parse peer which added song that's being persisted
                    if let addedPeerUUID = song.addedByUUID {
                        let uuidPredicate = NSPredicate(format: "uuid = %@", addedPeerUUID)
                        song.addedBy = realm.objects(DMEventPeer.self).filter(uuidPredicate).first
                    }
                    
                    // Parse peers who upvoted song that's being persisted
                    let uuidPredicate = NSPredicate(format: "uuid IN %@", song.upvotedByUUIDs)
                    let upvotees = realm.objects(DMEventPeer.self).filter(uuidPredicate)
                    song.upvotees.append(objectsIn: upvotees)
                    song.upvoteCount = upvotees.count
                    
                    realm.add(song, update: true)
                }
                return song
            }
    
        return result
    }
    
    @discardableResult
    func markAsPlayed(song: DMEventSong) -> Observable<DMEventSong> {

        return safeSongOnPersistenceScheduler(
            song: song,
            error: DMEventSongPersistenceServiceError.toggleFailed(song)
        )
        .flatMap { threadSafeSong -> Observable<DMEventSong> in
            return Realm.withRealm(
                operation: "marking song as played",
                error: DMEventSongPersistenceServiceError.toggleFailed(song)) { realm -> DMEventSong in
                    try realm.write {
                        if threadSafeSong.played == nil {
                            threadSafeSong.played = Date()
                        }
                    }
                return threadSafeSong
            }
        }
    }
    
    @discardableResult
    func upvote(song: DMEventSong, forUser user: DMEventPeer) -> Observable<DMEventSong> {
        return safeSongOnPersistenceScheduler(
            song: song,
            error: DMEventSongPersistenceServiceError.toggleFailed(song)
        )
        .flatMap { threadSafeSong -> Observable<DMEventSong> in
            return Realm.withRealm(
                operation: "upvoting song",
                error: DMEventSongPersistenceServiceError.upvoteFailed(song)) { realm -> DMEventSong in
                    try realm.write {
                        song.upvotees.append(user)
                        song.upvoteCount = song.upvoteCount + 1
                    }
                    return song
            }
        }
    }
    
    func songs() -> Observable<Results<DMEventSong>> {
        let result = Realm.withRealm(
            operation: "getting all songs",
            error: DMEventSongPersistenceServiceError.fetchingSongsFailed,
            scheduler: songPersistenceScheduler) { realm -> Results<DMEventSong> in
                let songs = realm.objects(DMEventSong.self)
                return songs
            }
            .flatMap { threadSafeSongs -> Observable<Results<DMEventSong>> in
                return Observable.collection(from: threadSafeSongs)
            }
        return result
    }

}

extension DMEventSongPersistenceService {
    
    func safeSongOnPersistenceScheduler(song: DMEventSong, error: Error) -> Observable<DMEventSong> {
        return Realm.safeObject(
            observeOn: MainScheduler.instance,
            subscribeOn: songPersistenceScheduler,
            fromReference: ThreadSafeReference(to: song),
            errorOnFailure: error
        )
    }
    
}
