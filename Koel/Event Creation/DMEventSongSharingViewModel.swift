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
import os.log

protocol DMEventSongsRepresentable {
    var songsSectioned: Observable<[SongSection]> { get }
}

protocol DMEventParticipantSongsEditable {
    var onUpvote: (DMEventSong) -> (CocoaAction) { get }
}

protocol DMEventHostSongsEditable {
    var onSongsDelete: CocoaAction { get }
    var skipSongForward: Observable<Void> { get }
    var updateSongToState: (DMEventSong, DMEventSongState) -> (Observable<Void>) { get }
}

protocol DMEventSongsManagerSeparatable {
    var addedSongs: Observable<[DMEventSong]> { get }
    var playedSongs: Observable<[DMEventSong]> { get }
    var playingSong: Observable<DMEventSong?> { get }
}

protocol DMEventSongSharingViewModelType {
    var songSharingService: DMEntitySharingService<DMEventSong> { get }
}

class DMEventSongSharingViewModel: DMEventSongSharingViewModelType, MultipeerViewModelType, DMEventSongsRepresentable, DMEventParticipantSongsEditable, DMEventHostSongsEditable, DMEventSongsManagerSeparatable {
    
    private let disposeBag = DisposeBag()
    private let songPersistenceService: DMEventSongPersistenceServiceType
    private let reachabilityService: ReachabilityService
    
    let songSharingService: DMEntitySharingService<DMEventSong>
    let multipeerService: DMEventMultipeerService
    
    private let songSortDescriptors = [
        SortDescriptor(keyPath: "upvoteCount", ascending: false),
        SortDescriptor(keyPath: "added", ascending: true)
    ]
    
    init(songPersistenceService: DMEventSongPersistenceServiceType,
         reachabilityService: ReachabilityService,
         songSharingService: DMEntitySharingService<DMEventSong>,
         multipeerService: DMEventMultipeerService) {
        
        self.songSharingService = songSharingService
        self.songPersistenceService = songPersistenceService
        self.multipeerService = multipeerService
        self.reachabilityService = reachabilityService
        
        multipeerService
            .receive()
            .map { (peer, data) -> DMEventSong? in
                do {
                    let song = try songSharingService.parse(fromData: data)
                    return song
                } catch _ {
                    return nil
                }
            }
            .filterNil()
            .subscribe(createAction.inputs)
            .disposed(by: disposeBag)
        
        multipeerService
            .receive()
            .map { (peer, data) -> [DMEventSong]? in
                do {
                    let songs = try DMEntitySharingService<[DMEventSong]>().parse(fromData: data)
                    return songs
                } catch _ {
                    return nil
                }
            }
            .filterNil()
            .flatMap { songsToStore in
                return self.songPersistenceService.store(songs: songsToStore)
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    lazy var addedSongs: Observable<[DMEventSong]> = {
        return songPersistenceService
            .songs
            .map { [unowned self] results in
                return results
                    .filter(forSongState: .added)
                    .sorted(by: self.songSortDescriptors)
                    .toArray()
            }
            .share(replay: 1, scope: .forever)
    }()
    
    lazy var playedSongs: Observable<[DMEventSong]> = {
        return songPersistenceService
            .songs
            .map { [unowned self] results in
                return results
                    .filter(forSongState: .played)
                    .sorted(by: self.songSortDescriptors)
                    .toArray()
            }
            .share(replay: 1, scope: .forever)
    }()
    
    lazy var playingSong: Observable<DMEventSong?> = {
        return songPersistenceService
            .songs
            .map { [unowned self] results in
                return results
                    .filter(forSongState: .playing)
                    .first
            }
            .startWith(nil)
            .share(replay: 1, scope: .forever)
    }()
    
    var songsSectioned: Observable<[SongSection]> {
        return Observable.combineLatest(addedSongs, playedSongs, playingSong) { (addedSongs, playedSongs, playingSong) in
            var sectionedSongs: [SongSection] = []
            
            if let playing = playingSong {
                sectionedSongs.append(SongSection(model: "Playing", items: [playing]))
            }
            
            sectionedSongs.append(contentsOf:  [
                SongSection(model: UIConstants.strings.queuedSongs, items: addedSongs),
                SongSection(model: UIConstants.strings.playedSongs, items: playedSongs)])
            return sectionedSongs
        }
        .observeOn(MainScheduler.instance)
    }
    
    //MARK: - Song creation
  
    private lazy var createAction: Action<DMEventSong, DMEventSong> = {
        return Action(workFactory: { [unowned self] (song: DMEventSong) -> Observable<DMEventSong> in
            return self.songPersistenceService.store(song: song)
        })
    }()
    
    //MARK: - Created song management
    
    lazy var onUpvote: (DMEventSong) -> (CocoaAction) = {
        return { [unowned self] song in

            let selfUUID = self.multipeerService.myEventPeer.primaryKeyRef
            let selfHasUpvoted = song.upvotees.map { $0.uuid }.contains(selfUUID)
            let canBeUpvotedBySelf = Observable.just(!selfHasUpvoted)

            let songStateIsAdded = song.rx.observe(DMEventSongState.self, "state")
                .map { $0 == .added }
            
            let canBeUpvoted = Observable
                .combineLatest(canBeUpvotedBySelf, songStateIsAdded)
                .map { $0 && $1 }

            return CocoaAction(
                enabledIf: canBeUpvoted,
                workFactory: { [unowned self] in
                    return self.songPersistenceService
                        .upvote(song: song, forUser: self.selfPeer.primaryKeyRef)
                        .share(withMultipeerService: self.multipeerService, sharingService: self.songSharingService)
                }
            )
        }
    }()
    
    lazy var updateSongToState: (DMEventSong, DMEventSongState) -> Observable<Void> = {
        return { song, state in
            self.songPersistenceService
                .update(song: song, toState: state)
                .share(withMultipeerService: self.multipeerService, sharingService: self.songSharingService)
        }
    }()
    
    lazy var skipSongForward: Observable<Void> = {
        return playingSong.filterNil().amb(addedSongs.map { $0.first }.filterNil())
            .take(1)
            .flatMap { song in
                return self.updateSongToState(song, .played)
            }
    }()
    
    lazy var onSongsDelete: CocoaAction = {
        return CocoaAction(workFactory: { [unowned self] in
            return self.songPersistenceService.deleteAllSongs()
        })
    }()
    
}

private extension Results where Element: DMEventSong {
    
    func filter(forSongState state: DMEventSongState) -> Results<Element> {
        return filter("state == \(state.rawValue)")
    }
    
}

extension Observable where Element: Codable {
    
    func share<SharingService: DMEntitySharingServiceType>(withMultipeerService multipeerService: DMEventMultipeerService, sharingService: SharingService) -> Observable<Void> where Element == SharingService.Entity {
        
        return self.withLatestFrom(multipeerService.connectedPeers()) { (entity, peers) -> Observable<Void> in
            if peers.isEmpty {
                os_log("No peers to share with: %@", String(describing: entity.self))
                return .just(())
            }
            os_log("➡️➡️➡️ sharing %@", String(describing: entity.self))
            let availablePeerIDs = peers.flatMap { $0.peerID }
            let encodedEntity = try! sharingService.encode(entity: entity)
            return multipeerService
                .send(toPeers: availablePeerIDs,
                      data: encodedEntity,
                      mode: MCSessionSendDataMode.reliable)
                .catchError{ error in
                    print(error)
                    return .just(())
                }
        }
        .flatMap { $0 }
    }

    
    
}
