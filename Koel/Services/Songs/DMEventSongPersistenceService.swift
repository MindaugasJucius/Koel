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
    
    var selfPeer: DMEventPeer
    
    
    @discardableResult
    func store(song: DMEventSong) -> Observable<DMEventSong> {
        let result = Realm.withRealm(
            operation: "persisting a song with id: \(song.uuid)",
            error: DMEventSongPersistenceServiceError.creationFailed,
            scheduler: songPersistenceScheduler) { realm -> DMEventSong in
                try realm.write {
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
                    song.upvotedBySelfPeer = song.upvotedByUUIDs.contains(self.selfPeer.primaryKeyRef)
                    
                    realm.add(song, update: true)
                }
                 return song
            }
    
        return result
    }
    
    @discardableResult
    func markAsPlayed(song: DMEventSong) -> Observable<DMEventSong> {
        let threadSafeSongReference = ThreadSafeReference(to: song)
        return Realm.withRealm(
            operation: "marking song as played",
            error: DMEventSongPersistenceServiceError.toggleFailed(song),
            scheduler: songPersistenceScheduler) { realm -> DMEventSong? in
                let resolvedSong = realm.resolve(threadSafeSongReference)
                try realm.write {
                    if resolvedSong?.played == nil {
                        resolvedSong?.played = Date()
                    }
                }
                return resolvedSong
            }

    }
    
    @discardableResult
    func upvote(song: DMEventSong, forUser userUUID: String) -> Observable<DMEventSong> {
        let threadSafeSongReference = ThreadSafeReference(to: song)
        return Realm.withRealm(
            operation: "upvoting song",
            error: DMEventSongPersistenceServiceError.upvoteFailed(song),
            scheduler: songPersistenceScheduler) { realm -> DMEventSong? in
                guard let resolvedSong = realm.resolve(threadSafeSongReference),
                    let fetchedUser = realm.object(ofType: DMEventPeer.self, forPrimaryKey: userUUID) else {
                    return .none
                }
                try realm.write {
                    resolvedSong.upvotees.append(fetchedUser)
                    resolvedSong.upvoteCount = resolvedSong.upvoteCount + 1
                    resolvedSong.upvotedBySelfPeer = true
                }
                return resolvedSong
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
