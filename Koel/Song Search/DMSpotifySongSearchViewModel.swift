//
//  DMSpotifySongSearchViewModel.swift
//  Koel
//
//  Created by Mindaugas on 25/03/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Action
import RxSwift

protocol DMSpotifySongSearchViewModelType: ViewModelType {
    
    var spotifySearchService: DMSpotifySearchServiceType { get }
    
    var searchResults: Observable<[SongSection]> { get }
    
    var removeSelectedSong: Action<DMEventSong, Void> { get }
    var addSelectedSong: Action<DMEventSong, Void> { get }
    
    var onClose: Action<[DMEventSong], Void> { get }
    var onDone: CocoaAction { get }
}

class DMSpotifySongSearchViewModel: DMSpotifySongSearchViewModelType {
    
    var sceneCoordinator: SceneCoordinatorType
    var spotifySearchService: DMSpotifySearchServiceType
    
    private var selectedSongs: [DMEventSong] = []
    
    var onClose: Action<[DMEventSong], Void>
    
    lazy var onDone: CocoaAction = {
        return CocoaAction(workFactory: { [unowned self] _ -> Observable<Void> in
            return self.onClose.execute(self.selectedSongs)
        })
    }()
    
    lazy var searchResults: Observable<[SongSection]> = {
        return spotifySearchService.savedTracks().map { songs in
            [SongSection(model: "Results", items: songs)]
        }.share()
    }()
    
    init(sceneCoordinator: SceneCoordinatorType, spotifySearchService: DMSpotifySearchServiceType, onClose: Action<[DMEventSong], Void>) {
        self.sceneCoordinator = sceneCoordinator
        self.spotifySearchService = spotifySearchService
        self.onClose = onClose
        
    }
    
    lazy var addSelectedSong: Action<DMEventSong, Void> = {
        return Action(workFactory: { [unowned self] (song: DMEventSong) -> Observable<Void> in
            self.selectedSongs.append(song)
            return Observable.just(())
        })
    }()
    
    lazy var removeSelectedSong: Action<DMEventSong, Void> = {
        return Action(workFactory: { [unowned self] (song: DMEventSong) -> Observable<Void> in
            if let songIndex = self.selectedSongs.index(of: song) {
                self.selectedSongs.remove(at: songIndex)
            } else {
                print("🤨 FAILURE to remove selected song: \(song.title).")
            }
            return Observable.just(())
        })
    }()
    
    
//    lazy var inviteAction: Action<(DMEventPeer), Void> = { this in
//        return Action(
//            workFactory: { (eventPeer: DMEventPeer) in
//                let hostContext = ContextKeys.isHost.dictionary
//                return this.multipeerService.connect(eventPeer.peerID, context: hostContext)
//        }
//        )
//    }(self)
    
}
