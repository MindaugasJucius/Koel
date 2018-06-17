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
import RxDataSources

enum SectionItem {
    case songSectionItem(song: DMEventSong)
    case loadingSectionItem
    case emptySectionItem
}

enum SongSectionModel: SectionModelType {
    
    typealias Item = SectionItem
    
    var items: [SectionItem] {
        switch self {
        case .songSection(title: _, items: let songItems):
            return songItems
        case .loadingSection(item: let loadingItem):
            return [loadingItem]
        case .emptySection(item: let emptyItem):
            return [emptyItem]
        }
    }

    init(original: SongSectionModel, items: [SectionItem]) {
        switch original {
        case let .songSection(title: title, items: _):
            self = .songSection(title: title, items: items)
        case .loadingSection(item: _):
            self = .loadingSection(item: items.first!)
        case .emptySection(item: _):
            self = .emptySection(item: items.first!)
        }
    }

    case songSection(title: String, items: [SectionItem])
    case loadingSection(item: SectionItem)
    case emptySection(item: SectionItem)
}

protocol DMSpotifySongSearchViewModelType: ViewModelType {
    
    var spotifySearchService: DMSpotifySearchServiceType { get }

    var results: Driver<[SongSectionModel]> { get }
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
    
    private let isLoadingRelay = BehaviorRelay(value: true)
    
    var isLoading: Driver<Bool> {
        return self.isLoadingRelay.asDriver()
    }
    
    private var allSavedTracks: [DMEventSong] = []
    
    lazy var results: Driver<[SongSectionModel]> = {
        return self.loadNextPageOffsetTrigger
            .do(onNext: { _ in self.isLoadingRelay.accept(true) })
            .flatMap { [unowned self] _ in
                self.spotifySearchService.savedTracks()
                    .asDriver(onErrorJustReturn: [])
            }
            .map { [unowned self] newSavedTracks in
                self.allSavedTracks.append(contentsOf: newSavedTracks)
                return self.allSavedTracks.map { SectionItem.songSectionItem(song: $0) }
            }
            .map { [SongSectionModel.songSection(title: "Results", items: $0)] }
            .do(onNext: { _ in self.isLoadingRelay.accept(false) })
            .startWith([SongSectionModel.emptySection(item: SectionItem.emptySectionItem)])
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
            .flatMap { error in
                sceneCoordinator.promptFor(error.localizedDescription, cancelAction: "ok", actions: nil)
            }
            .do(onNext: { _ in self.isLoadingRelay.accept(false) }) // let user perform requests after errors
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
