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
    case deleteAllSongsFailed
}

protocol DMEventSongPersistenceServiceType {
    
    var selfPeer: DMEventPeer { get }
    
    @discardableResult
    func store(songs: [DMEventSong]) -> Observable<[DMEventSong]>
    
    @discardableResult
    func store(song: DMEventSong) -> Observable<DMEventSong>
    
    @discardableResult
    func update(song: DMEventSong, toState state: DMEventSongState) -> Observable<DMEventSong> 
    
    @discardableResult
    func upvote(song: DMEventSong, forUser: String) -> Observable<DMEventSong>
    
    var songs: Observable<Results<DMEventSong>> { get }
    
    @discardableResult
    func deleteAllSongs() -> Observable<Void>
    
}

private let songPersistenceScheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS.background)

class DMEventSongPersistenceService: DMEventSongPersistenceServiceType {
    
    var selfPeer: DMEventPeer
    
    init(selfPeer: DMEventPeer) {
        self.selfPeer = selfPeer
    }
    
    @discardableResult
    func store(song: DMEventSong) -> Observable<DMEventSong> {
        return store(songs: [song])
            .flatMap{ songs -> Observable<DMEventSong> in
                .just(songs.first!)
            }
    }
    
    @discardableResult
    func store(songs: [DMEventSong]) -> Observable<[DMEventSong]> {
        return Realm.withRealmArray(
            operation: "persisting songs with: \(songs)",
            error: DMEventSongPersistenceServiceError.creationFailed,
            scheduler: songPersistenceScheduler) { realm -> [DMEventSong] in
                try realm.write {
                    songs.forEach { song in
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
                        song.primaryKeyRef = song.uuid
                    }

                    realm.add(songs, update: true)
                }

                return songs
            }
    }
    
    @discardableResult
    func update(song: DMEventSong, toState state: DMEventSongState) -> Observable<DMEventSong> {
        let threadSafeSongReference = ThreadSafeReference(to: song)
        return Realm.withRealm(
            operation: "marking song: \(song.title) as \(state) \(state.rawValue)",
            error: DMEventSongPersistenceServiceError.toggleFailed(song),
            scheduler: songPersistenceScheduler) { realm -> DMEventSong? in
                let resolvedSong = realm.resolve(threadSafeSongReference)
                try realm.write {
                    resolvedSong?.state = state
                    if state == .played {
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
                }
                return resolvedSong
        }
    }

    func deleteAllSongs() -> Observable<Void> {
        return Observable<Void>.create { (observer) -> Disposable in
            do {
                let realm = try Realm()
                let songsResult = realm.objects(DMEventSong.self)
                try realm.write {
                    realm.delete(songsResult)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch let error {
                observer.onError(error)
            }
            return Disposables.create()
        }.subscribeOn(songPersistenceScheduler)
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
