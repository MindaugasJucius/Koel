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

    var results: Driver<[SongSection]> { get }
    var isLoading: Driver<Bool> { get }
    
    var removeSelectedSong: Action<DMEventSong, Void> { get }
    var addSelectedSong: Action<DMEventSong, Void> { get }
    
    var onClose: Action<[DMEventSong], Void> { get }
    var onDone: CocoaAction { get }

    var loadNextPageOffsetTrigger: Driver<()> { get set }
    
}

class DMSpotifySongSearchViewModel: DMSpotifySongSearchViewModelType {

//    var isLoading: Signal<Bool>
//    var isRefreshing: Signal<Bool>
//    var error: Signal<NSError>
    
    private let isLoadingRelay = BehaviorRelay(value: false)
    
    var isLoading: Driver<Bool> {
        return self.isLoadingRelay.asDriver()
    }
    
    private var allSavedTracks: [DMEventSong] = []
    
    lazy var results: Driver<[SongSection]> = {
        return self.loadNextPageOffsetTrigger
            .withLatestFrom(self.isLoading)
            .filter { !$0 }
            .do(onNext: { _ in self.isLoadingRelay.accept(true) })
            .flatMap { [unowned self] _ in
                self.spotifySearchService.savedTracks()
                    .asDriver(onErrorJustReturn: [])
                    .do(onNext: { _ in self.isLoadingRelay.accept(false) })
                    .filter { !$0.isEmpty }
            }
            .map { [unowned self] newSavedTracks in
                self.allSavedTracks.append(contentsOf: newSavedTracks)
                return self.allSavedTracks
            }
            .map { [SongSection(model: "Results", items: $0)] }
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
    
    init(sceneCoordinator: SceneCoordinatorType, spotifySearchService: DMSpotifySearchServiceType, onClose: Action<[DMEventSong], Void>) {
        self.sceneCoordinator = sceneCoordinator
        self.spotifySearchService = spotifySearchService
        self.onClose = onClose
        self.loadNextPageOffsetTrigger = Driver.empty()
        
        spotifySearchService.resultError
            .asObservable()
            .flatMap { error in
                sceneCoordinator.promptFor(error.localizedDescription, cancelAction: "ok", actions: nil)
            }
            .subscribe()
            .disposed(by: disposeBag)
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
