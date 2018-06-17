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
    
    func savedTracks() -> Observable<[DMEventSong]>
    
}

class DMSpotifySearchService: DMSpotifySearchServiceType {
    
    private let authService: DMSpotifyAuthService
    private let reachabilityService: ReachabilityService
    
    private var latestSavedTracksPagingObject: PagingObject<SavedTrack>? = nil
    
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
        return e.enumerated().flatMap { (attempt, error) -> Observable<Int> in
            let nsError = error as NSError
            
            if nsError.code == -1009 {
                return self.reachabilityService.reachability
                    .filter { $0.reachable }
                    .map { _ in 1 }
            }
            print("network error")
            return Observable.error(error)
        }
    }
    
    func savedTracks() -> Observable<[DMEventSong]> {
        return self.authService.currentSessionObservable
            .flatMap { [unowned self] _ in Observable.just(self.latestSavedTracksPagingObject) }
            .flatMap { [unowned self] paggingObject -> Observable<PagingObject<SavedTrack>> in
                guard let paggingObject = paggingObject else {
                    return self.initial { Spartan.getSavedTracks(limit: 50, success: $0, failure: $1) }
                        .timeout(5, scheduler: MainScheduler.instance)
                }
                
                if paggingObject.canMakeNextRequest {
                    //TODO: add caching to pagingObject.getNext
                    return self.following(pagingObject: paggingObject)
                        .timeout(5, scheduler: MainScheduler.instance)
                }
                
                return .empty()
            }
            .do(onNext: { [unowned self] pagingObject in
                self.latestSavedTracksPagingObject = pagingObject
            })
            .map { pagingObject -> [DMEventSong] in
                return pagingObject.items.map { savedTrack -> DMEventSong in
                    let eventSong = DMEventSong()
                    eventSong.spotifyURI = savedTrack.track.uri
                    eventSong.title = savedTrack.track.name
                    let artistTitle = savedTrack.track.album.artists.reduce("", { currentTitle, artist in
                        return currentTitle.appending("\(artist.name!) ")
                    })
                    eventSong.artistTitle = artistTitle
                    return eventSong
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
