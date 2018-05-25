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

    var songsSectioned: Observable<[SongSection]> { get }
    var addedSongs: Observable<[DMEventSong]> { get }
    var playedSongs: Observable<[DMEventSong]> { get }
    
    var upNextSong: Observable<DMEventSong?> { get }
    var playingSong: Observable<DMEventSong?> { get }
    
    var onSongSearch: CocoaAction { get }
    var onSongsDelete: CocoaAction { get }
    var onUpdateSongToState: Action<(DMEventSong, DMEventSongState), Void> { get }
    
    func onUpvote(song: DMEventSong) -> CocoaAction
}

class DMEventSongSharingViewModel: DMEventSongSharingViewModelType {
    
    private let disposeBag = DisposeBag()
    private var songPersistenceService: DMEventSongPersistenceServiceType
    
    var songSharingService: DMEntitySharingService<DMEventSong>
    var multipeerService: DMEventMultipeerService
    var sceneCoordinator: SceneCoordinatorType
    
    private let songSortDescriptors = [
        SortDescriptor(keyPath: "upvoteCount", ascending: false),
        SortDescriptor(keyPath: "added", ascending: true)
    ]
    
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
    
    lazy var upNextSong: Observable<DMEventSong?> = {
        return songPersistenceService
            .songs
            .map { [unowned self] results in
                return results
                    .filter(forSongState: .queued)
                    .first
            }
            .startWith(nil)
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
        return Observable.combineLatest(addedSongs, playedSongs, playingSong, upNextSong) { (addedSongs, playedSongs, playingSong, upNextSong) in
            var sectionedSongs: [SongSection] = []
            
            if let playing = playingSong {
                sectionedSongs.append(SongSection(model: "Playing", items: [playing]))
            }
            
            if let upNext = upNextSong {
                sectionedSongs.append(SongSection(model: "Up next", items: [upNext]))
            }
            
            sectionedSongs.append(contentsOf:  [
                SongSection(model: UIConstants.strings.queuedSongs, items: addedSongs),
                SongSection(model: UIConstants.strings.playedSongs, items: playedSongs)])
            return sectionedSongs
        }
        .observeOn(MainScheduler.instance)
    }
    
    //MARK: - Song search
    
    private func onSearchClose() -> Action<[DMEventSong], Void> {
        return Action<[DMEventSong], Void>(workFactory: { [unowned self] (songs) -> Observable<Void> in
            
            return self.songPersistenceService
                .store(songs: songs)
                .filter { !$0.isEmpty }
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
        let canBeUpvotedBySelf = song.rx.observe(Bool.self, "upvotedBySelfPeer")
            .filterNil() //never nil (default value in DMEventSong = false)
            .map { !$0 }

        let songNotPlayed = song.rx.observe(Date.self, "played")
            .map { $0 == nil }
        
        let canBeUpvoted = Observable
            .combineLatest(canBeUpvotedBySelf, songNotPlayed)
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
    
    var onUpdateSongToState: Action<(DMEventSong, DMEventSongState), Void> {
        return Action(workFactory: { [unowned self] (song: DMEventSong, state: DMEventSongState) -> Observable<Void> in
            return self.songPersistenceService.update(song: song,
                                                      toState: state)
                .share(withMultipeerService: self.multipeerService,
                       sharingService: self.songSharingService)
        })
    }
    
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

private extension Observable where Element: Codable {
    
    func share<SharingService: DMEntitySharingServiceType>(withMultipeerService multipeerService: DMEventMultipeerService, sharingService: SharingService) -> Observable<Void> where Element == SharingService.Entity {
        
        return self.withLatestFrom(multipeerService.connectedPeers()) { (entity, peers) -> Observable<Void> in
            if peers.isEmpty {
                os_log("No peers to share with: %@", String(describing: entity.self))
                return Observable<Void>.empty()
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
