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

protocol DMEventSongSharingViewModelType: MultipeerViewModelType {
    
    var sceneCoordinator: SceneCoordinatorType { get }
    var songSharingService: DMEntitySharingService<DMEventSong> { get }
    var songPersistenceService: DMEventSongPersistenceServiceType { get }

    var songsSectioned: Observable<[SongSection]> { get }
    
    var onSongSearch: CocoaAction { get }
    var onPlayed: Action<DMEventSong, Void> { get }
    
    func onUpvote(song: DMEventSong) -> CocoaAction
}

class DMEventSongSharingViewModel: DMEventSongSharingViewModelType {
    
    private let disposeBag = DisposeBag()

    var songSharingService: DMEntitySharingService<DMEventSong>
    var songPersistenceService: DMEventSongPersistenceServiceType
    var multipeerService: DMEventMultipeerService
    var sceneCoordinator: SceneCoordinatorType
    
    init(songPersistenceService: DMEventSongPersistenceServiceType,
         songSharingService: DMEntitySharingService<DMEventSong>,
         multipeerService: DMEventMultipeerService,
         sceneCoordinator: SceneCoordinatorType) {
        self.songSharingService = songSharingService
        self.songPersistenceService = songPersistenceService
        self.multipeerService = multipeerService
        self.sceneCoordinator = sceneCoordinator
        
        multipeerService
            .receive()
            .map { (peer, data) -> DMEventSong? in
                do {
                    let song = try songSharingService.parse(fromData: data)
                    print("retrieved a song: \(song), added uuid: \(song.addedByUUID), upvoted uuids: \(song.upvotedByUUIDs)")
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
            .map { (peer, data) -> [DMEventSong] in
                let songs = try DMEntitySharingService<[DMEventSong]>().parse(fromData: data)
                print("retrieved songs: \(songs)")
                return songs
            }
            .flatMap { songs -> Observable<Observable<DMEventSong>> in
                let storeObservables = songs.map { song in
                    return songPersistenceService.store(song: song)
                }
                return Observable.from(storeObservables)
            }
            .merge()
            .subscribe()
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
    
    //MARK: - Song search
    
    private func onSearchClose() -> Action<[DMEventSong], Void> {
        return Action<[DMEventSong], Void>(workFactory: { [unowned self] (songs) -> Observable<Void> in
            
            let storeObservables = songs.map { [unowned self] song -> Observable<DMEventSong> in
                return self.songPersistenceService.store(song: song)
            }
            
            return Observable.from(storeObservables)
                .merge()
                .reduce([], accumulator: { (array, song) -> [DMEventSong] in
                    return array + [song]
                })
                .share(withMultipeerService: self.multipeerService, sharingService: DMEntitySharingService<[DMEventSong]>())
                .map { _ in }
                .do(onCompleted: { [unowned self] in
                    self.sceneCoordinator.pop(animated: true)
                }
            )
        })
    }
  
    lazy var onSongSearch: CocoaAction = {
        return CocoaAction { [unowned self] in
            let spotifyAuthService = DMSpotifyAuthService(sceneCoordinator: self.sceneCoordinator)
            let spotifySearchService = DMSpotifySearchService(authService: spotifyAuthService)
            let spotifySongSearchViewModel = DMSpotifySongSearchViewModel(
                sceneCoordinator: self.sceneCoordinator,
                spotifySearchService: spotifySearchService,
                onClose: self.onSearchClose()
            )
            
            return self.sceneCoordinator.transition(
                to: Scene.searchSpotify(spotifySongSearchViewModel),
                type: .modal
            )
        }
    }()
    
    //MARK: - Song creation
  
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
        return self
            .withLatestFrom(multipeerService.connectedPeers()) { (entity, peers) -> Observable<Void> in
                os_log("➡️➡️➡️ sharing %@", String(describing: entity.self))
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
