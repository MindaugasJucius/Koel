//
//  DMEventSongServiceType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 08/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift

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
    func upvote(song: DMEventSong, forUser: String) -> Observable<DMEventSong>
    
    var songs: Observable<Results<DMEventSong>> { get }
    
}
