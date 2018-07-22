//
//  DMSpotifySearchContainerViewModel.swift
//  Koel
//
//  Created by Mindaugas on 15/07/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import Action
import RxCocoa
import RxSwift
import Spartan

protocol DMSpotifySearchContainerViewModelType: ViewModelType {
    
    var reachability: Observable<ReachabilityStatus> { get }
    var queueSelectedSongs: CocoaAction { get }
    
    var tracksViewModel: DMSpotifySongSearchViewModelType { get }
    
    func searchViewModel(withQuery query: String, itemType: ItemSearchType) -> DMSpotifySongSearchViewModelType
}

class DMSpotifySearchContainerViewModel: NSObject, DMSpotifySearchContainerViewModelType {
    
    let reachabilityService: ReachabilityService
    let spotifyAuthService: DMSpotifyAuthService
    let promptCoordinator: PromptCoordinating
    let onQueueSelectedSongs: Action<[DMSearchResultSong], Void>
    
    var reachability: Observable<ReachabilityStatus> {
        return reachabilityService.reachability
    }
    
    lazy var songSelected: Action<DMSearchResultSong, Void> = {
        return Action(workFactory: { [unowned self] (selectedSong: DMSearchResultSong) -> Observable<Void> in
            var selectedSongs = self.selectedSongsRelay.value
            selectedSongs.append(selectedSong)
            self.selectedSongsRelay.accept(selectedSongs)
            return Observable.just(())
        })
    }()
    
    lazy var songRemoved: Action<DMSearchResultSong, Void> = {
        return Action(workFactory: { [unowned self] (selectedSong: DMSearchResultSong) -> Observable<Void> in
            if let songIndex = self.selectedSongsRelay.value.index(of: selectedSong) {
                var selectedSongs = self.selectedSongsRelay.value
                selectedSongs.remove(at: songIndex)
                self.selectedSongsRelay.accept(selectedSongs)
            }
            return Observable.just(())
        })
    }()
    
    private var selectedSongsRelay = BehaviorRelay<[DMSearchResultSong]>(value: [])

    lazy var queueSelectedSongs: CocoaAction = {
        let enabledIf = selectedSongsRelay.map { $0.count > 0 }.distinctUntilChanged()
        return CocoaAction(enabledIf: enabledIf, workFactory: { _ -> Observable<Void> in
            return self.onQueueSelectedSongs.execute(self.selectedSongsRelay.value)
        })
    }()
    
    
    init(reachabilityService: ReachabilityService,
         spotifyAuthService: DMSpotifyAuthService,
         promptCoordinator: PromptCoordinating,
         onQueueSelectedSongs: Action<[DMSearchResultSong], Void>) {
        self.reachabilityService = reachabilityService
        self.spotifyAuthService = spotifyAuthService
        self.onQueueSelectedSongs = onQueueSelectedSongs
        self.promptCoordinator = promptCoordinator
    }
    
    lazy var tracksViewModel: DMSpotifySongSearchViewModelType = {
        let initialRequest = DMSpotifySearchService<SavedTrack, DMSearchResultSong>.initialRequest(completionBlocks: { (success, failure) in
            return Spartan.getSavedTracks(limit: 50,
                                          market: Spartan.currentCountryCode,
                                          success: success,
                                          failure: failure)
            
        })
        
        let spotifySearchService = DMSpotifySearchService<SavedTrack, DMSearchResultSong>(authService: spotifyAuthService,
                                                                      reachabilityService: self.reachabilityService,
                                                                      initialRequest: initialRequest)
        
        return DMSpotifySongSearchViewModel(promptCoordinator: promptCoordinator,
                                            spotifySearchService: spotifySearchService,
                                            songSelected: songSelected,
                                            songRemoved: songRemoved)
    }()
    
    func searchViewModel(withQuery query: String, itemType: ItemSearchType) -> DMSpotifySongSearchViewModelType {
        let initialRequest = DMSpotifySearchService<Track, DMSearchResultSong>.initialRequest(completionBlocks: { (success, failure) in
            return Spartan.search(query: query,
                                  type: itemType,
                                  success: success,
                                  failure: failure)
        })
        
        let spotifySearchService = DMSpotifySearchService<Track, DMSearchResultSong>(authService: spotifyAuthService,
                                                                 reachabilityService: self.reachabilityService,
                                                                 initialRequest: initialRequest)
        
        return DMSpotifySongSearchViewModel(promptCoordinator: promptCoordinator,
                                            spotifySearchService: spotifySearchService,
                                            songSelected: songSelected,
                                            songRemoved: songRemoved)

    }
    
}
