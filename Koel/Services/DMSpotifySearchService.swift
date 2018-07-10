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

protocol DMSpotifySearchServiceType {
    
    var resultError: Observable<Error> { get }
    
    var trackResults: Driver<[SongSearchResultSectionModel]> { get }
    
    var offsetTriggerRelay: PublishSubject<()> { get }
    var refreshTriggerRelay: PublishSubject<()> { get }
    
}

class DMSpotifySearchService<T: Paginatable & Mappable>: DMSpotifySearchServiceType {

    typealias PagingObjectSuccess = ((PagingObject<T>) -> Void)
    typealias PagingObjectFailure = (SpartanError) -> (Void)
    
    private let disposeBag = DisposeBag()
    
    private let authService: DMSpotifyAuthService
    private let reachabilityService: ReachabilityService
    
    private var latestPagingObject: PagingObject<T>? = nil
    private var allTracks: [DMSearchResultSong] = []
    
    private var initialRequest: Observable<PagingObject<T>>
    
    private let resultErrorRelay: PublishRelay<Error> = PublishRelay()

    let offsetTriggerRelay: PublishSubject<()>
    let refreshTriggerRelay: PublishSubject<()>
    
    private let resultsSubject: PublishSubject<[DMSearchResultSong]> = PublishSubject()
    
    var trackResults: Driver<[SongSectionModel]> {
        return resultsSubject.asObservable()
            .map { [unowned self] newSavedTracks in
                self.allTracks.append(contentsOf: newSavedTracks)
                return self.allTracks.map { SectionItem.songSectionItem(song: $0) }
            }
            .map { [SongSectionModel.songSection(title: nil, items: $0)] }
            .asDriver(onErrorJustReturn: valueOnError)
            .startWith([SongSectionModel.emptySection(item: SectionItem.emptySectionItem)])
    }
    
    
    var resultError: Observable<Error> {
        return resultErrorRelay.asObservable()
    }
    
    private var valueOnError: [SongSectionModel] {
        return allTracks.isEmpty ? [SongSectionModel.emptySection(item: SectionItem.emptySectionItem)] : []
    }
    
    init(authService: DMSpotifyAuthService,
         reachabilityService: ReachabilityService,
         initialRequest: Observable<PagingObject<T>>) {
        self.offsetTriggerRelay = PublishSubject()
        self.refreshTriggerRelay = PublishSubject()
        self.authService = authService
        self.reachabilityService = reachabilityService
        self.initialRequest = initialRequest
        
        setupObservables()
    }
    
    private func setupObservables() {
        offsetTriggerRelay.asObservable()
            .flatMap { _ in
                return self.results
            }
            .bind(to: resultsSubject)
            .disposed(by: disposeBag)
        
        Observable.zip(offsetTriggerRelay.asObservable(), resultsSubject.asObservable())
            .map { $0.1 }
            .downloadImages()
            .bind(to: resultsSubject)
            .disposed(by: disposeBag)
    }
    
    static func initial(completionBlocks: @escaping ((success: PagingObjectSuccess, failure: PagingObjectFailure)) -> ()) -> Observable<PagingObject<T>> {
        return Observable<PagingObject<T>>.create { observer in
            let completion: (success: PagingObjectSuccess, failure: PagingObjectFailure) = (
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
    
    private func following(pagingObject: PagingObject<T>) -> Observable<PagingObject<T>> {
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
    
    private var results: Observable<[DMSearchResultSong]> {
        return self.authService.spotifySession(forAction: UIConstants.strings.SPTSearchTracks)
            .flatMap { [unowned self] _ in
                return Observable.just(self.latestPagingObject)
            }
            .flatMap { [unowned self] paggingObject -> Observable<PagingObject<T>> in
                guard let paggingObject = paggingObject else {
                    return self.initialRequest
                }
                
                if paggingObject.canMakeNextRequest {
                    return self.following(pagingObject: paggingObject)
                }
                
                return .empty()
            }
            .do(onNext: { [unowned self] pagingObject in
                self.latestPagingObject = pagingObject
            })
            .map { pagingObject -> [DMSearchResultSong] in
                return pagingObject.items.compactMap { savedTrack -> DMSearchResultSong? in
                    return DMSearchResultSong.create(from: savedTrack)
                }
            }
            .retryWhen(retryHandler)
            .do(onError: { error in self.resultErrorRelay.accept(error) })
            .subscribeOn(concurrentScheduler)
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
