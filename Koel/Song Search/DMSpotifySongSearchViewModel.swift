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
import RxCocoa

enum DMSpotifySongSearchState<T, E: Error> {
    case success(T)
    case failure(E)
}

protocol DMSpotifySongSearchViewModelType: ViewModelType {
    
    var spotifySearchService: DMSpotifySearchServiceType { get }
    
    var searchResults: Observable<[SongSection]> { get }
    
    var results: Signal<[SongSection]> { get }
    var error: Signal<NSError> { get }
    var isLoading: Signal<Bool> { get }
    var isRefreshing: Signal<Bool> { get }
    
    var removeSelectedSong: Action<DMEventSong, Void> { get }
    var addSelectedSong: Action<DMEventSong, Void> { get }
    
    var onClose: Action<[DMEventSong], Void> { get }
    var onDone: CocoaAction { get }

    var loadNextPageOffsetTrigger: Driver<()> { get set }
    
}

class DMSpotifySongSearchViewModel: DMSpotifySongSearchViewModelType {
    
    var isLoading: Signal<Bool>
    var isRefreshing: Signal<Bool>
    var error: Signal<NSError>
    
    
    private var allSavedTracks: [DMEventSong] = []
    
    
//        .map { [unowned self] newSavedTracks in
//            self.allSavedTracks.append(contentsOf: newSavedTracks)
//            return self.allSavedTracks
//    }
    
    lazy var results: Signal<[SongSection]> = {
        return self.loadNextPageOffsetTrigger
            .flatMap { [unowned self] _ in
                self.spotifySearchService.savedTracks().asSignal(onErrorJustReturn: [])
            }
            .map { songs in
                [SongSection(model: "Results", items: songs)]
            }
    }()
    
    
    private let disposeBag = DisposeBag()
    
    var loadNextPageOffsetTrigger: Driver<()>

    let sceneCoordinator: SceneCoordinatorType
    let spotifySearchService: DMSpotifySearchServiceType
    
    private var selectedSongs: [DMEventSong] = []
    
    let onClose: Action<[DMEventSong], Void>
    
    lazy var onDone: CocoaAction = {
        return CocoaAction(workFactory: { [unowned self] _ -> Observable<Void> in
            return self.onClose.execute(self.selectedSongs)
        })
    }()
    
    lazy var searchResults: Observable<[SongSection]> = {
        return self.loadNextPageOffsetTrigger.asObservable()
            .flatMap { [unowned self] _ in self.spotifySearchService.savedTracks() }
            .map { songs in
                [SongSection(model: "Results", items: songs)]
            }
    }()
    

    init(sceneCoordinator: SceneCoordinatorType, spotifySearchService: DMSpotifySearchServiceType, onClose: Action<[DMEventSong], Void>) {
        self.sceneCoordinator = sceneCoordinator
        self.spotifySearchService = spotifySearchService
        self.onClose = onClose
        self.loadNextPageOffsetTrigger = Driver.empty()
        //self.results = Driver.empty()
        
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

}
