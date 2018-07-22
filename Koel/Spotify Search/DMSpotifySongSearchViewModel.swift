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
import Spartan
import ObjectMapper

enum SectionItem<T: Representing>: Equatable {
    
    case initialSectionItem
    case emptySectionItem
    case songSectionItem(representable: T)
    
    static func ==(lhs: SectionItem, rhs: SectionItem) -> Bool {
        return lhs.identity == rhs.identity
    }
}

extension SectionItem: IdentifiableType {
    var identity: String {
        switch self {
        case .songSectionItem(representable: let representable):
            return representable.identity
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

typealias SongSearchResultSectionModel<T: Representing> = AnimatableSectionModel<SectionType, SectionItem<T>>

//extension AnimatableSectionModel where Section == SectionType, ItemType == SectionItem {
//
//    static let empty = AnimatableSectionModel.init(model: .empty, items: [SectionItem.emptySectionItem])
//    static let initial = AnimatableSectionModel.init(model: .initial, items: [SectionItem.initialSectionItem])
//
//}

protocol DMSpotifySongSearchViewModelType {
    
    var songResults: Driver<[SongSearchResultSectionModel]> { get }
    var isLoading: Driver<Bool> { get }
    var isRefreshing: Driver<Bool> { get }
    
//    var sectionItemSelected: Action<SectionItem, Void> { get }
//    var sectionItemDeselected: Action<SectionItem, Void> { get }
    
    var offsetTriggerObserver: AnyObserver<()> { get }
    var refreshTriggerObserver: AnyObserver<()> { get }
}

class DMSpotifySongSearchViewModel<Object: Paginatable & Mappable, RepresentableType: Representing>: DMSpotifySongSearchViewModelType {
    
    typealias SectionType = SongSearchResultSectionModel<RepresentableType>
    
    private let disposeBag = DisposeBag()
    
    private let isRefreshingRelay = BehaviorRelay(value: false)
    
    var isRefreshing: Driver<Bool> {
        return self.isRefreshingRelay.asDriver()
    }
    
    private let isLoadingRelay = BehaviorRelay(value: false)
    
    var isLoading: Driver<Bool> {
        return self.isLoadingRelay.asDriver()
    }
    
    private var resultRelay: BehaviorRelay<[SectionType]> = BehaviorRelay(value: [])
    
    var songResults: Driver<[SongSearchResultSectionModel<RepresentableType>]> {
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
    let spotifySearchService: DMSpotifySearchService<Object, RepresentableType>
   
    init(promptCoordinator: PromptCoordinating,
         spotifySearchService: DMSpotifySearchService<Object, RepresentableType>,
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
                    let songSectionItems = newSavedTracks.map { SectionItem.songSectionItem(representable: $0) }
                    return [SectionType.init(model: .songs, items: songSectionItems)]
                    
                } else {
                    return []//[SectionType.empty]
                }
            }
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
    }
    
//    lazy var sectionItemSelected: Action<SectionItem<RepresentableType>, Void> = {
//        return Action(workFactory: { [unowned self] (sectionItem: SectionItem) -> Observable<Void> in
//            if case SectionItem.songSectionItem(song: let selectedSong) = sectionItem {
//                self.songSelected.execute(selectedSong)
//            }
//            return Observable.just(())
//        })
//    }()
//
//    lazy var sectionItemDeselected: Action<SectionItem<RepresentableType>, Void> = {
//        return Action(workFactory: { [unowned self] (sectionItem: SectionItem) -> Observable<Void> in
//            if case SectionItem.songSectionItem(song: let selectedSong) = sectionItem {
//                self.songRemoved.execute(selectedSong)
//            }
//            return Observable.just(())
//        })
//    }()

}
