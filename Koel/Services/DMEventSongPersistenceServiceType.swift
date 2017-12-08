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
    case updateFailed(DMEventSong)
    case deletionFailed(DMEventSong)
    case toggleFailed(DMEventSong)
}

protocol DMEventSongPersistenceServiceType {
    
    @discardableResult
    func createSong(title: String) -> Observable<DMEventSong>
    
    @discardableResult
    func played(song: DMEventSong) -> Observable<DMEventSong>
    
    func songs() -> Observable<Results<DMEventSong>>
    
}
