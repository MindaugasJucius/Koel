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
    
    @discardableResult
    func store(song: DMEventSong) -> Observable<DMEventSong>
    
    @discardableResult
    func markAsPlayed(song: DMEventSong) -> Observable<DMEventSong>

    @discardableResult
    func upvote(song: DMEventSong, forUser: DMEventPeer) -> Observable<DMEventSong>
    
    func songs() -> Observable<Results<DMEventSong>>
    
}
