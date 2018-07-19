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
    
    case initialSectionItem
    case emptySectionItem
    case songSectionItem(song: DMSearchResultSong)
    
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

    case initial
    case empty
    case songs

    var identity: String {
        return self.rawValue
    }
}

typealias SongSearchResultSectionModel = AnimatableSectionModel<SectionType, SectionItem>

extension AnimatableSectionModel where Section == SectionType, ItemType == SectionItem {
    
    static let empty = AnimatableSectionModel.init(model: .empty, items: [SectionItem.emptySectionItem])
    static let initial = AnimatableSectionModel.init(model: .initial, items: [SectionItem.initialSectionItem])
    
}

protocol DMSpotifySongSearchViewModelType {
    var songResults: Driver<[SongSearchResultSectionModel]> { get }
    var isLoading: Driver<Bool> { get }
    var isRefreshing: Driver<Bool> { get }
    
    var sectionItemSelected: Action<SectionItem, Void> { get }
    var sectionItemDeselected: Action<SectionItem, Void> { get }
    
    var offsetTriggerObserver: AnyObserver<()> { get }
    var refreshTriggerObserver: AnyObserver<()> { get }
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
    
    private var resultRelay: BehaviorRelay<[SongSearchResultSectionModel]> = BehaviorRelay(value: [SongSearchResultSectionModel.initial])
    
    var songResults: Driver<[SongSearchResultSectionModel]> {
        return resultRelay.asDriver()
    }
    
    var offsetTriggerObserver: AnyObserver<()> {
        return offsetTriggerRelay.asObserver()
    }
    
    private var offsetTriggerRelay: PublishSubject<()> = PublishSubject()
    
    var refreshTriggerObserver: AnyObserver<()> {
        return refreshTriggerRelay.asObserver()
    }
    
    private var refreshTriggerRelay: PublishSubject<()> = PublishSubject()
    
    var songSelected: Action<DMSearchResultSong, Void>
    var songRemoved: Action<DMSearchResultSong, Void>
    
    let promptCoordinator: PromptCoordinating
    let spotifySearchService: DMSpotifySearchServiceType
   
    init(promptCoordinator: PromptCoordinating,
         spotifySearchService: DMSpotifySearchServiceType,
         songSelected: Action<DMSearchResultSong, Void>,
         songRemoved: Action<DMSearchResultSong, Void>) {
        self.promptCoordinator = promptCoordinator
        self.spotifySearchService = spotifySearchService
        self.songSelected = songSelected
        self.songRemoved = songRemoved

        spotifySearchService.resultError
            .flatMap { error in
                promptCoordinator.promptFor(error.localizedDescription, cancelAction: "ok", actions: nil)
            }
            .do(onNext: { _ in self.isLoadingRelay.accept(false) }) // let user perform requests after errors
            .subscribe()
            .disposed(by: disposeBag)

        offsetTriggerRelay.asObservable()
            .do(onNext: { [unowned self] in self.isLoadingRelay.accept(true) })
            .flatMap { self.spotifySearchService.trackResults }
            .do(onNext: { [unowned self] _ in self.isLoadingRelay.accept(false) })
            .map { newSavedTracks in
                if newSavedTracks.isNotEmpty {
                    let songSectionItems = newSavedTracks.map { SectionItem.songSectionItem(song: $0) }
                    return [SongSearchResultSectionModel.init(model: .songs, items: songSectionItems)]
                    
                } else {
                    return [SongSearchResultSectionModel.empty]
                }
            }
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
    }
    
    lazy var sectionItemSelected: Action<SectionItem, Void> = {
        return Action(workFactory: { [unowned self] (sectionItem: SectionItem) -> Observable<Void> in
            if case SectionItem.songSectionItem(song: let selectedSong) = sectionItem {
                self.songSelected.execute(selectedSong)
            }
            return Observable.just(())
        })
    }()
    
    lazy var sectionItemDeselected: Action<SectionItem, Void> = {
        return Action(workFactory: { [unowned self] (sectionItem: SectionItem) -> Observable<Void> in
            if case SectionItem.songSectionItem(song: let selectedSong) = sectionItem {
                self.songRemoved.execute(selectedSong)
            }
            return Observable.just(())
        })
    }()

}
