//
//  DMSpotifySearchService.swift
//  Koel
//
//  Created by Mindaugas on 25/03/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Spartan
import RxSwift
import ObjectMapper

enum Result<T, E: Error> {
    case success(T)
    case failure(E)
}

typealias PagingObjectSuccess<T: Paginatable & Mappable> = ((PagingObject<T>) -> Void)
typealias PagingObjectFailure = (SpartanError) -> (Void)

protocol DMSpotifySearchServiceType {
    
    var authService: DMSpotifyAuthService { get }
    
    func savedTracks() -> Observable<[DMEventSong]>
    
}

class DMSpotifySearchService: DMSpotifySearchServiceType {
    
    let authService: DMSpotifyAuthService
    
    private var latestSavedTracksPagingObject: PagingObject<SavedTrack>? = nil
    private var allSavedTracks: [DMEventSong] = []
    
    init(authService: DMSpotifyAuthService) {
        self.authService = authService
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
    
    func savedTracks() -> Observable<[DMEventSong]> {
        return authService.currentSessionObservable
            .flatMap { [unowned self] _ in Observable.just(self.latestSavedTracksPagingObject) }
            .flatMap { [unowned self] paggingObject -> Observable<PagingObject<SavedTrack>> in
                guard let paggingObject = paggingObject else {
                    return self.initial { Spartan.getSavedTracks(limit: 50, success: $0, failure: $1) }
                }
                
                if paggingObject.canMakeNextRequest {
                    return self.following(pagingObject: paggingObject)
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
                    }
                    )
                    eventSong.artistTitle = artistTitle
                    return eventSong
                }
            }
            .map { [unowned self] newSavedTracks in
                self.allSavedTracks.append(contentsOf: newSavedTracks)
                return self.allSavedTracks
            }
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
