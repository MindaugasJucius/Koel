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
    
    private func withRealm<T>(_ operation: String, action: (Realm) throws -> T) -> T? {
        do {
            let realm = try Realm()
            return try action(realm)
        } catch let err {
            print("Failed \(operation) realm with error: \(err)")
            return nil
        }
    }

    @discardableResult
    func store(song: DMEventSong) -> Observable<DMEventSong> {
        let result = withRealm("creating") { realm -> Observable<DMEventSong> in
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
                
                realm.add(song)
            }
            return .just(song)
        }
        return result ?? .error(DMEventSongPersistenceServiceError.creationFailed)
    }
    
    @discardableResult
    func markAsPlayed(song: DMEventSong) -> Observable<DMEventSong> {
        let result = withRealm("marking as played") { realm -> Observable<DMEventSong> in
            try realm.write {
                if song.played == nil {
                    song.played = Date()
                }
            }
            return .just(song)
        }
        return result ?? .error(DMEventSongPersistenceServiceError.toggleFailed(song))
    }
    
    @discardableResult
    func upvote(song: DMEventSong, forUser user: DMEventPeer) -> Observable<DMEventSong> {
        let result = withRealm("upvoting") { realm -> Observable<DMEventSong> in
            try realm.write {
                song.upvotees.append(user)
                song.upvoteCount = song.upvoteCount + 1
            }
            return .just(song)
        }
        return result ?? .error(DMEventSongPersistenceServiceError.upvoteFailed(song))
    }
    
    func songs() -> Observable<Results<DMEventSong>> {
        let result = withRealm("getting all songs") { realm -> Observable<Results<DMEventSong>> in
            let songs = realm.objects(DMEventSong.self)
            return Observable.collection(from: songs)
        }
        return result ?? .empty()
    }
    
    
}
