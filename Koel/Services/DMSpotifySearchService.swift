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

typealias SpartanMapped = ([DMEventSong], Bool)

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
    
    private func initialRequest() -> Observable<PagingObject<SavedTrack>> {
        return Observable<PagingObject<SavedTrack>>.create { observer in
            _ = Spartan.getSavedTracks(limit: 50,
                                       offset: 0,
                                       success: { pagingObject in
                observer.onNext(pagingObject)
                observer.onCompleted()
            }, failure: { error in
                if let error = error.nsError {
                    observer.onError(error)
                    observer.onCompleted()
                }
            })
            return Disposables.create()
        }
    }
    
    private func followingRequest(pagingObject: PagingObject<SavedTrack>) -> Observable<PagingObject<SavedTrack>> {
        return Observable<PagingObject<SavedTrack>>.create { observer in
            pagingObject.getNext(
                success: { pagingObject in
                    observer.onNext(pagingObject)
                    observer.onCompleted()
                },
                failure: { error in
                    if let error = error.nsError {
                        observer.onError(error)
                        observer.onCompleted()
                    }
            })
            return Disposables.create()
        }
    }
  
    func savedTracks() -> Observable<[DMEventSong]> {
        return authService.currentSessionObservable
            .flatMap { [unowned self] _ in Observable.just(self.latestSavedTracksPagingObject) }
            .flatMap { [unowned self] paggingObject -> Observable<PagingObject<SavedTrack>> in
                guard let paggingObject = paggingObject else {
                    return self.initialRequest()
                }
                
                if paggingObject.canMakeNextRequest {
                    return self.followingRequest(pagingObject: paggingObject)
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
