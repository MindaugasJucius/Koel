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
    func createSong(title: String) -> Observable<DMEventSong> {
        let result = withRealm("creating") { realm -> Observable<DMEventSong> in
            let song = DMEventSong()
            song.title = title
            try realm.write {
                song.id = (realm.objects(DMEventSong.self).max(ofProperty: "id") ?? 0) + 1
                realm.add(song)
            }
            return .just(song)
        }
        return result ?? .error(DMEventSongPersistenceServiceError.creationFailed)
    }
    
    @discardableResult
    func played(song: DMEventSong) -> Observable<DMEventSong> {
        let result = withRealm("toggling") { realm -> Observable<DMEventSong> in
            try realm.write {
                if song.played == nil {
                    song.played = Date()
                }
            }
            return .just(song)
        }
        return result ?? .error(DMEventSongPersistenceServiceError.toggleFailed(song))
    }
    
    func songs() -> Observable<Results<DMEventSong>> {
        let result = withRealm("getting tasks") { realm -> Observable<Results<DMEventSong>> in
            let realm = try Realm()
            let songs = realm.objects(DMEventSong.self)
            return Observable.collection(from: songs)
        }
        return result ?? .empty()
    }
    
    
}
