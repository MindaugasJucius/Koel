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
    
    case initial
    case empty
    case representable(representable: T)
    
    static func ==(lhs: SectionItem, rhs: SectionItem) -> Bool {
        return lhs.identity == rhs.identity
    }
}

extension SectionItem: IdentifiableType {
    var identity: String {
        switch self {
        case .representable(representable: let representable):
            return representable.identity
        default:
            return String(describing: self)
        }
    }
}

enum SectionType: String, IdentifiableType {
    
    case representables

    var identity: String {
        return self.rawValue
    }
}

typealias SongSearchResultSectionModel<T: Representing> = AnimatableSectionModel<SectionType, SectionItem<T>>


protocol ResultsContainingType {
    
    //    var sectionItemSelected: Action<SectionItem, Void> { get }
    //    var sectionItemDeselected: Action<SectionItem, Void> { get }
    
}

protocol DMSpotifySongSearchViewModelType {
    
    associatedtype Model: Representing
    
    var songResults: Driver<[SongSearchResultSectionModel<Model>]> { get }
    
}

class DMSpotifySearchResultsViewModel<Object: Paginatable & Mappable, RepresentableType: Representing>: DMSpotifySongSearchViewModelType {
    
    typealias SectionType = SongSearchResultSectionModel<RepresentableType>
    
    private let empty = [SectionType.init(model: .representables, items: [SectionItem.empty])]
    private let initial = [SectionType.init(model: .representables, items: [SectionItem.initial])]
    
    private let disposeBag = DisposeBag()
    
    private lazy var resultRelay: BehaviorRelay<[SectionType]> = BehaviorRelay(value: initial)
    
    var songResults: Driver<[SongSearchResultSectionModel<RepresentableType>]> {
        return resultRelay.asDriver()
    }
    
    var loadingViewModel: LoadingStateConsumingViewModelType
    var triggersViewModel: TriggerObservingViewModelType
    
    let promptCoordinator: PromptCoordinating
    let spotifySearchService: DMSpotifySearchService<Object, RepresentableType>
   
    init(promptCoordinator: PromptCoordinating,
         spotifySearchService: DMSpotifySearchService<Object, RepresentableType>,
         loadingViewModel: LoadingStateConsumingViewModelType,
         triggersViewModel: TriggerObservingViewModelType) {
        
        self.loadingViewModel = loadingViewModel
        self.triggersViewModel = triggersViewModel
        self.promptCoordinator = promptCoordinator
        self.spotifySearchService = spotifySearchService

        spotifySearchService.resultError
            .flatMap { error in
                promptCoordinator.promptFor(error.localizedDescription, cancelAction: "ok", actions: nil)
            }
            .map { _ in false }
            .bind(to: loadingViewModel.loading)
            .disposed(by: disposeBag)

        triggersViewModel.offsetTrigger
            .do(onNext: { [unowned self] in self.loadingViewModel.loading.on(.next(true)) })
            .flatMap { self.spotifySearchService.trackResults }
            .do(onNext: { [unowned self] _ in self.loadingViewModel.loading.on(.next(false)) })
            .map { newSavedTracks in
                if newSavedTracks.isNotEmpty {
                    let songSectionItems = newSavedTracks.map { SectionItem.representable(representable: $0) }
                    return [SectionType.init(model: .representables, items: songSectionItems)]
                } else {
                    return self.empty
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
