//
//  DMEventSongSharingModelType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/23/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Action
import RxSwift
import MultipeerConnectivity
import RealmSwift

protocol DMEventSongSharingViewModelType: MultipeerViewModelType {
    
    var songSharingService: DMEntitySharingService<DMEventSong> { get }
    var songPersistenceService: DMEventSongPersistenceServiceType { get }

    var songsSectioned: Observable<[SongSection]> { get }
    
    var onSongCreate: CocoaAction { get }
    var onPlayed: Action<DMEventSong, Void> { get }
    
    func onUpvote(song: DMEventSong) -> CocoaAction
}

class DMEventSongSharingViewModel: DMEventSongSharingViewModelType {
    
    private let disposeBag = DisposeBag()
    
    var songSharingService: DMEntitySharingService<DMEventSong>
    var songPersistenceService: DMEventSongPersistenceServiceType
    var multipeerService: DMEventMultipeerService
    
    init(songPersistenceService: DMEventSongPersistenceServiceType,
         songSharingService: DMEntitySharingService<DMEventSong>,
         multipeerService: DMEventMultipeerService) {
        self.songSharingService = songSharingService
        self.songPersistenceService = songPersistenceService
        self.multipeerService = multipeerService
        
        multipeerService
            .receive()
            .map { (peer, data) -> DMEventSong in
                let song = try songSharingService.parse(fromData: data)
                print("retrieved a song: \(song), added uuid: \(song.addedByUUID), upvoted uuids: \(song.upvotedByUUIDs)")
                return song
            }
            .subscribe(createAction.inputs)
            .disposed(by: disposeBag)
    }
    
    var songsSectioned: Observable<[SongSection]> {
        return songPersistenceService.songs()
            .map { results in
                
                let songSortDescriptors = [
                    SortDescriptor(keyPath: "upvoteCount", ascending: false),
                    SortDescriptor(keyPath: "added", ascending: true)
                ]

                let queuedSongs = results
                    .filter("played == nil")
                    .sorted(by: songSortDescriptors)
                
                let playedSongs = results
                    .filter("played != nil")
                    .sorted(byKeyPath: "played", ascending: false)
                
                return [
                    SongSection(model: UIConstants.strings.queuedSongs, items: queuedSongs.toArray()),
                    SongSection(model: UIConstants.strings.playedSongs, items: playedSongs.toArray())
                ]
            }
            .observeOn(MainScheduler.instance)
    }
    
    //MARK: - Song creation
  
    lazy var onSongCreate: CocoaAction = {
        return CocoaAction { [unowned self] in
            let song = DMEventSong()
            song.title = "songy"
            song.addedByUUID = self.selfPeer.primaryKeyRef
            song.upvotedByUUIDs = [self.selfPeer.primaryKeyRef]
            return self.createAction.execute(song)
                .share(withMultipeerService: self.multipeerService, sharingService: self.songSharingService)
        }
    }()

    private lazy var createAction: Action<DMEventSong, DMEventSong> = {
        return Action(workFactory: { [unowned self] (song: DMEventSong) -> Observable<DMEventSong> in
            return self.songPersistenceService.store(song: song)
        })
    }()
    
    //MARK: - Created song management
    
    func onUpvote(song: DMEventSong) -> CocoaAction {
        let availableForUpvote = song.rx.observe(Bool.self, "upvotedBySelfPeer")
            .filterNil()
            .map { !$0 }
        
        return CocoaAction(
            enabledIf: availableForUpvote,
            workFactory: { [unowned self] in
                return self.songPersistenceService
                    .upvote(song: song, forUser: self.selfPeer.primaryKeyRef)
                    .share(withMultipeerService: self.multipeerService, sharingService: self.songSharingService)
            }
        )
    }
    
    lazy var onPlayed: Action<DMEventSong, Void> = {
        return Action(workFactory: { [unowned self] (song: DMEventSong) -> Observable<Void> in
            return self.songPersistenceService
                .markAsPlayed(song: song)
                .share(withMultipeerService: self.multipeerService, sharingService: self.songSharingService)
        })
    }()
 
}

private extension Observable where Element: Codable {
    
    func share<SharingService: DMEntitySharingServiceType>(withMultipeerService multipeerService: DMEventMultipeerService, sharingService: SharingService) -> Observable<Void> where Element == SharingService.Entity {
        return self.withLatestFrom(multipeerService.connectedPeers()) { (entity, peers) -> Observable<Void> in
            let availablePeerIDs = peers.flatMap { $0.peerID }
            let encodedEntity = try! sharingService.encode(entity: entity)
            return multipeerService.send(
                toPeers: availablePeerIDs,
                data: encodedEntity,
                mode: MCSessionSendDataMode.reliable
            )
        }
        .flatMap { $0 }

    }
    
}
