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

protocol DMSpotifySongSearchViewModelType {
    var songResults: Driver<[SongSectionModel]> { get }
    var isLoading: Driver<Bool> { get }
    var isRefreshing: Driver<Bool> { get }
    
    var removeSelectedSong: Action<DMEventSong, Void> { get }
    var addSelectedSong: Action<DMEventSong, Void> { get }
    
    var offsetTriggerRelay: PublishRelay<()> { get }
    var refreshTriggerRelay: PublishRelay<()> { get }
}

class DMSpotifySongSearchViewModel: DMSpotifySongSearchViewModelType {

    private let disposeBag = DisposeBag()
    
    private let isRefreshingRelay = BehaviorRelay(value: false)
    
    var isRefreshing: Driver<Bool> {
        return self.isRefreshingRelay.asDriver()
    }
    
    private let isLoadingRelay = BehaviorRelay(value: false)
    
    var isLoading: Driver<Bool> {
        return self.isLoadingRelay.asDriver()
    }
    
    private let songResultRelay: BehaviorRelay<[SongSectionModel]>
    
    var songResults: Driver<[SongSectionModel]> {
        return songResultRelay.asDriver()
    }
    
    let offsetTriggerRelay: PublishRelay<()>
    let refreshTriggerRelay: PublishRelay<()>
    
    let promptCoordinator: PromptCoordinating
    let spotifySearchService: DMSpotifySearchServiceType
    
    private var selectedSongs: [DMEventSong] = []
    
    init(promptCoordinator: PromptCoordinating, spotifySearchService: DMSpotifySearchServiceType) {
        self.promptCoordinator = promptCoordinator
        self.spotifySearchService = spotifySearchService
        
        self.refreshTriggerRelay = PublishRelay()
        self.songResultRelay = BehaviorRelay(value: [SongSectionModel.emptySection(item: SectionItem.emptySectionItem)])
        self.offsetTriggerRelay = PublishRelay()
        
        spotifySearchService.resultError
            .flatMap { error in
                promptCoordinator.promptFor(error.localizedDescription, cancelAction: "ok", actions: nil)
            }
            .do(onNext: { _ in self.isLoadingRelay.accept(false) }) // let user perform requests after errors
            .subscribe()
            .disposed(by: disposeBag)

        refreshTriggerRelay.asObservable()
            .withLatestFrom(isLoading.asObservable())
            .filter { !$0 }
            .do(onNext: { _ in self.isRefreshingRelay.accept(true) })
            .flatMap { [unowned self] _ in
                self.spotifySearchService.savedTracks(resetResults: true)
            }
            .do(onNext: { _ in self.isRefreshingRelay.accept(false) })
            .bind(to: songResultRelay)
            .disposed(by: disposeBag)

        offsetTriggerRelay.asObservable()
            .withLatestFrom(isRefreshing.asObservable())
            .filter { !$0 }
            .do(onNext: { _ in self.isLoadingRelay.accept(true) })
            .flatMap { [unowned self] _ in
                self.spotifySearchService.savedTracks(resetResults: false)
            }
            .do(onNext: { _ in self.isLoadingRelay.accept(false) })
            .bind(to: songResultRelay)
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
