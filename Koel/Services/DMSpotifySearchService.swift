//
//  DMSpotifySearchService.swift
//  Koel
//
//  Created by Mindaugas on 25/03/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Spartan
import RxCocoa
import RxSwift
import ObjectMapper

private let concurrentScheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS.userInitiated)

typealias PagingObjectSuccess<T: Paginatable & Mappable> = ((PagingObject<T>) -> Void)
typealias PagingObjectFailure = (SpartanError) -> (Void)

protocol DMSpotifySearchServiceType {
    
    var resultError: Observable<Error> { get }
    
    func savedTracks(resetResults reset: Bool) -> Driver<[SongSectionModel]>
    func map(searchResults: [DMSearchResultSong]) -> [DMEventSong]
}

class DMSpotifySearchService: DMSpotifySearchServiceType {
    
    private let authService: DMSpotifyAuthService
    private let reachabilityService: ReachabilityService
    
    private var latestSavedTracksPagingObject: PagingObject<SavedTrack>? = nil
    private var allSavedTracks: [DMSearchResultSong] = []
    
    private let resultErrorRelay: PublishRelay<Error> = PublishRelay()

    var resultError: Observable<Error> {
        return resultErrorRelay.asObservable()
    }
    
    init(authService: DMSpotifyAuthService, reachabilityService: ReachabilityService) {
        self.authService = authService
        self.reachabilityService = reachabilityService
    }
    
    private func initial<T: Paginatable & Mappable>(completionBlocks: @escaping ((success: PagingObjectSuccess<T>, failure: PagingObjectFailure)) -> ()) -> Observable<PagingObject<T>> {
        return Observable<PagingObject<T>>.create { observer in
            let completion: (success: PagingObjectSuccess<T>, failure: PagingObjectFailure) = (
                success: { pagingObject in
                    observer.onNext(pagingObject)
                    observer.onCompleted()
                },
                failure: { error in
                    let nsError = error.nsError ?? NSError(domain: error.errorMessage, code: 0, userInfo: nil)
                    observer.onError(nsError)
                }
            )
            completionBlocks(completion)
            return Disposables.create()
        }
    }
    
    private func following<T: Paginatable & Mappable>(pagingObject: PagingObject<T>) -> Observable<PagingObject<T>> {
        return Observable<PagingObject<T>>.create { observer in
            pagingObject.getNext(
                success: { pagingObject in
                    observer.onNext(pagingObject)
                    observer.onCompleted()
                },
                failure: { error in
                    let nsError = error.nsError ?? NSError(domain: error.errorMessage, code: 0, userInfo: nil)
                    observer.onError(nsError)
                }
            )
            return Disposables.create()
        }
    }
    
    lazy var retryHandler: (Observable<Error>) -> Observable<Int> = { e in
        let waitForReachability = self.reachabilityService.reachability
            .filter { $0.reachable }
            .map { _ in 1 }
        
        return e.enumerated()
            .withLatestFrom(self.reachabilityService.reachability) { (errorTuple, reachabilityStatus) -> Observable<Int> in
                let error = errorTuple.element as NSError

                //Error codes: http://nshipster.com/nserror/
                let isConnectivityError = -1011...(-998) ~= error.code
                if isConnectivityError, case ReachabilityStatus.unreachable = reachabilityStatus {
                    return waitForReachability
                }

                print("received error in \(#file). Code: \(error.code)")
                return .error(error)
            }
            .flatMap { $0 }
    }
    
    func savedTracks(resetResults reset: Bool) -> Driver<[SongSectionModel]> {
        if reset {
            self.latestSavedTracksPagingObject = nil
            self.allSavedTracks = []
        }
        
        let valueOnError = allSavedTracks.isEmpty ? [SongSectionModel.emptySection(item: SectionItem.emptySectionItem)] : []

        return self.authService.spotifySession(forAction: UIConstants.strings.SPTSearchTracks)
            .flatMap { [unowned self] _ in
                return Observable.just(self.latestSavedTracksPagingObject)
            }
            .flatMap { [unowned self] paggingObject -> Observable<PagingObject<SavedTrack>> in
                guard let paggingObject = paggingObject else {
                    return self.initial { Spartan.getSavedTracks(limit: 50, market: Spartan.currentCountryCode, success: $0, failure: $1) }
                }
                
                if paggingObject.canMakeNextRequest {
                    return self.following(pagingObject: paggingObject)
                }
                
                return .empty()
            }
            .do(onNext: { [unowned self] pagingObject in
                self.latestSavedTracksPagingObject = pagingObject
            })
            .map { pagingObject -> [DMSearchResultSong] in
                return pagingObject.items.map { savedTrack -> DMSearchResultSong in
                    return DMSearchResultSong.create(from: savedTrack)
                }
            }

            .map { [unowned self] newSavedTracks in
                self.allSavedTracks.append(contentsOf: newSavedTracks)
                return self.allSavedTracks.map { SectionItem.songSectionItem(song: $0) }
            }
            .map { [SongSectionModel.songSection(title: "Results", items: $0)] }
            .retryWhen(retryHandler)
            .do(onError: { error in self.resultErrorRelay.accept(error) })
            .subscribeOn(concurrentScheduler)
            .asDriver(onErrorJustReturn: valueOnError)
    }
    
    func map(searchResults: [DMSearchResultSong]) -> [DMEventSong] {
        return searchResults.map { DMEventSong.from(searchResultSong: $0) }
    }


}

extension Spartan {
    
    static var currentCountryCode: CountryCode? {
        get {
            var countryCode: CountryCode? = nil
            
            if let countryCodeString = NSLocale.current.regionCode {
                countryCode = CountryCode.init(rawValue: countryCodeString)
            }
            return countryCode
        }
    }
    
}
