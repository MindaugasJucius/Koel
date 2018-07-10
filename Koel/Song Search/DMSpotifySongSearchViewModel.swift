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

enum SectionItem: Equatable {
    case songSectionItem(song: DMSearchResultSong)
    case loadingSectionItem
    case emptySectionItem
    
    static func ==(lhs: SectionItem, rhs: SectionItem) -> Bool {
        if case SectionItem.songSectionItem(song: let rhsSong) = rhs,
            case SectionItem.songSectionItem(song: let lhsSong) = lhs {
            return rhsSong == lhsSong
        }
        return true
    }
}

extension SectionItem: IdentifiableType {
    var identity: String {
        switch self {
        case .songSectionItem(song: let song):
            return song.spotifyURI
        default:
            return ""
        }
    }
}

enum SectionType: String, IdentifiableType {

    case empty
    case loading
    case songs

    var identity: String {
        return self.rawValue
    }
}

typealias SongSearchResultSectionModel = AnimatableSectionModel<SectionType, SectionItem>


protocol DMSpotifySongSearchViewModelType {
    var songResults: Driver<[SongSearchResultSectionModel]> { get }
    var isLoading: Driver<Bool> { get }
    var isRefreshing: Driver<Bool> { get }
    
    var sectionItemSelected: Action<SectionItem, Void> { get }
    var sectionItemDeselected: Action<SectionItem, Void> { get }
    
    var offsetTriggerRelay: PublishSubject<()> { get }
    var refreshTriggerRelay: PublishSubject<()> { get }
    
    var queueSelectedSongs: CocoaAction { get }
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
    
    var songResults: Driver<[SongSearchResultSectionModel]> {
        return spotifySearchService.trackResults
    }
    
    var offsetTriggerRelay: PublishSubject<()> {
        return spotifySearchService.offsetTriggerRelay
    }
    
    var refreshTriggerRelay: PublishSubject<()> {
        return spotifySearchService.refreshTriggerRelay
    }
    
    let promptCoordinator: PromptCoordinating
    let spotifySearchService: DMSpotifySearchServiceType
   
    private var selectedSongsRelay = BehaviorRelay<[DMSearchResultSong]>(value: [])
    var onQueueSelectedSongs: Action<[DMSearchResultSong], Void>
        
    lazy var queueSelectedSongs: CocoaAction = {
        let enabledIf = selectedSongsRelay.map { $0.count > 0 }.distinctUntilChanged()
        return CocoaAction(enabledIf: enabledIf, workFactory: { _ -> Observable<Void> in
            return self.onQueueSelectedSongs.execute(self.selectedSongsRelay.value)
        })
    }()
    
    init(promptCoordinator: PromptCoordinating,
         spotifySearchService: DMSpotifySearchServiceType,
         onQueueSelectedSongs: Action<[DMSearchResultSong], Void>) {
        self.promptCoordinator = promptCoordinator
        self.spotifySearchService = spotifySearchService
        self.onQueueSelectedSongs = onQueueSelectedSongs

        spotifySearchService.resultError
            .flatMap { error in
                promptCoordinator.promptFor(error.localizedDescription, cancelAction: "ok", actions: nil)
            }
            .do(onNext: { _ in self.isLoadingRelay.accept(false) }) // let user perform requests after errors
            .subscribe()
            .disposed(by: disposeBag)

        // remove selected songs on queueing
        queueSelectedSongs.executionObservables.map { _ in [] }
            .bind(to: selectedSongsRelay)
            .disposed(by: disposeBag)
    }
    
    lazy var sectionItemSelected: Action<SectionItem, Void> = {
        return Action(workFactory: { [unowned self] (sectionItem: SectionItem) -> Observable<Void> in
            if case SectionItem.songSectionItem(song: let selectedSong) = sectionItem {
                var selectedSongs = self.selectedSongsRelay.value
                selectedSongs.append(selectedSong)
                self.selectedSongsRelay.accept(selectedSongs)
            }
            return Observable.just(())
        })
    }()
    
    lazy var sectionItemDeselected: Action<SectionItem, Void> = {
        return Action(workFactory: { [unowned self] (sectionItem: SectionItem) -> Observable<Void> in
            if case SectionItem.songSectionItem(song: let selectedSong) = sectionItem,
                let songIndex = self.selectedSongsRelay.value.index(of: selectedSong) {
                var selectedSongs = self.selectedSongsRelay.value
                selectedSongs.remove(at: songIndex)
                self.selectedSongsRelay.accept(selectedSongs)
            }
            return Observable.just(())
        })
    }()

}
