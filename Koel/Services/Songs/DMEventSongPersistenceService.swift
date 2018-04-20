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

enum DMEventSongPersistenceServiceError: Error {
    case creationFailed
    case fetchingSongsFailed
    case updateFailed(DMEventSong)
    case deletionFailed(DMEventSong)
    case toggleFailed(DMEventSong)
    case upvoteFailed(DMEventSong)
}

protocol DMEventSongPersistenceServiceType {
    
    var selfPeer: DMEventPeer { get }
    
    @discardableResult
    func store(song: DMEventSong) -> Observable<DMEventSong>
    
    @discardableResult
    func markAsPlayed(song: DMEventSong) -> Observable<DMEventSong>
    
    @discardableResult
    func enqueueAlreadyPlayedSong(song: DMEventSong) -> Observable<DMEventSong>
    
    @discardableResult
    func update(song: DMEventSong, toState state: DMEventSongState) -> Observable<DMEventSong> 
    
    @discardableResult
    func upvote(song: DMEventSong, forUser: String) -> Observable<DMEventSong>
    
    var songs: Observable<Results<DMEventSong>> { get }
    
}

private let songPersistenceScheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS.background)

class DMEventSongPersistenceService: DMEventSongPersistenceServiceType {
    
    var selfPeer: DMEventPeer
    
    init(selfPeer: DMEventPeer) {
        self.selfPeer = selfPeer
    }
    
    @discardableResult
    func store(song: DMEventSong) -> Observable<DMEventSong> {
        return Realm.withRealm(
            operation: "persisting a song with id: \(song.uuid)",
            error: DMEventSongPersistenceServiceError.creationFailed,
            scheduler: songPersistenceScheduler) { realm -> DMEventSong in
                try realm.write {
                    // Parse peer which added song that's being persisted
                    if let addedPeerUUID = song.addedByUUID {
                        let uuidPredicate = NSPredicate(format: "uuid = %@", addedPeerUUID)
                        song.addedBy = realm.objects(DMEventPeer.self).filter(uuidPredicate).first
                    }
                    
                    if song.added == .none {
                        song.added = Date()
                    }
                    
                    // Parse peers who upvoted song that's being persisted
                    let uuidPredicate = NSPredicate(format: "uuid IN %@", song.upvotedByUUIDs)
                    let upvotees = realm.objects(DMEventPeer.self).filter(uuidPredicate)
                    song.upvotees.append(objectsIn: upvotees)
                    song.upvoteCount = upvotees.count
                    song.upvotedBySelfPeer = song.upvotedByUUIDs.contains(self.selfPeer.primaryKeyRef)
                    
                    realm.add(song, update: true)
                }
                song.primaryKeyRef = song.uuid
                return song
            }
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
                    resolvedSong?.played = Date()
                    resolvedSong?.state = .played
                }
                return resolvedSong
            }

    }
    
    @discardableResult
    func enqueueAlreadyPlayedSong(song: DMEventSong) -> Observable<DMEventSong> {
        song.primaryKeyRef = song.uuid //why?
        return Realm.update(entity: song,
                            operation: "enqueueing already played song: \(song.title)",
                            onScheduler: songPersistenceScheduler) { song in
                                song.played = nil
                                song.added = Date()
                                return song
                            }
    }
    
    @discardableResult
    func update(song: DMEventSong, toState state: DMEventSongState) -> Observable<DMEventSong> {
        let threadSafeSongReference = ThreadSafeReference(to: song)
        return Realm.withRealm(
            operation: "marking song: \(song.title) as spt queued",
            error: DMEventSongPersistenceServiceError.toggleFailed(song),
            scheduler: songPersistenceScheduler) { realm -> DMEventSong? in
                let resolvedSong = realm.resolve(threadSafeSongReference)
                try realm.write {
                    resolvedSong?.state = state
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
    
    lazy var songs: Observable<Results<DMEventSong>> = {
        let result = Realm.withRealm(
            operation: "getting all songs",
            error: DMEventSongPersistenceServiceError.fetchingSongsFailed,
            scheduler: songPersistenceScheduler) { realm -> Results<DMEventSong> in
                let songs: Results<DMEventSong> = realm.objects(DMEventSong.self)
                return songs
            }
            .flatMap { threadSafeSongs -> Observable<Results<DMEventSong>> in
                return Observable.collection(from: threadSafeSongs)
            }
        return result.share()
    }()

}
