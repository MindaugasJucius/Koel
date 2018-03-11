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
    
    var songSharingService: DMEventSongSharingServiceType { get }
    var songPersistenceService: DMEventSongPersistenceServiceType { get }

    var songsSectioned: Observable<[SongSection]> { get }
    
    var onSongCreate: CocoaAction { get }
    var onPlayed: Action<DMEventSong, Void> { get }

    func onUpvote(song: DMEventSong) -> CocoaAction
}

class DMEventSongSharingViewModel: DMEventSongSharingViewModelType {
    
    private let disposeBag = DisposeBag()
    
    var songSharingService: DMEventSongSharingServiceType
    var songPersistenceService: DMEventSongPersistenceServiceType
    var multipeerService: DMEventMultipeerService
    
    init(songPersistenceService: DMEventSongPersistenceServiceType,
         songSharingService: DMEventSongSharingServiceType,
         multipeerService: DMEventMultipeerService) {
        self.songSharingService = songSharingService
        self.songPersistenceService = songPersistenceService
        self.multipeerService = multipeerService
        
        multipeerService
            .receive()
            .map { receivedInfo -> DMEventSong in
                let song = try songSharingService.parseSong(fromData: receivedInfo.1)
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
                    SortDescriptor(keyPath: "added", ascending: false)
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
                .do(
                    onNext: { [unowned self] persistedSong in
                        self.share(song: persistedSong)
                    }
                )
                .map { _ in }
            }
    }()
    
    private func share(song: DMEventSong) {
        multipeerService.connectedPeers()
            .map { peers in
                return (peers.flatMap { $0.peerID }, song)
            }
            .subscribe(shareAction.inputs)
            .dispose()
    }
    
    private lazy var createAction: Action<DMEventSong, DMEventSong> = {
        return Action(workFactory: { [unowned self] (song: DMEventSong) -> Observable<DMEventSong> in
            return self.songPersistenceService.store(song: song)
        })
    }()
    
    private lazy var shareAction: Action<([MCPeerID], DMEventSong), Void> = {
        return Action(workFactory: { [unowned self] (peers: [MCPeerID], song: DMEventSong) -> Observable<Void> in
            do {
                let songData = try self.songSharingService.encode(song: song)
                return self.multipeerService.send(toPeers: peers, data: songData, mode: MCSessionSendDataMode.reliable)
            }
            catch {
                return Observable.empty()
            }
        })
    }()
    
    //MARK: - Created song management
    
    func onUpvote(song: DMEventSong) -> CocoaAction {
        let upvoteesContainSelf = song.addedBy?.uuid == selfPeer.primaryKeyRef
        return CocoaAction(
            enabledIf: Observable.just(!upvoteesContainSelf),
            workFactory: { [unowned self] in
                return self.songPersistenceService
                    .upvote(song: song, forUser: self.selfPeer)
                    .map { _ in }
            }
        )
    }
    
    lazy var onPlayed: Action<DMEventSong, Void> = {
        return Action(workFactory: { [unowned self] (song: DMEventSong) -> Observable<Void> in
            return self.songPersistenceService.markAsPlayed(song: song).map { _ in }
        })
    }()
    
}
