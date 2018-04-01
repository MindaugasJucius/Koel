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

protocol DMSpotifySearchServiceType {
    
    var authService: DMSpotifyAuthService { get }
    
    func savedTracks() -> Observable<[DMEventSong]>
    
}

class DMSpotifySearchService: DMSpotifySearchServiceType {
    
    var authService: DMSpotifyAuthService
    
    init(authService: DMSpotifyAuthService) {
        self.authService = authService
    }
  
    func savedTracks() -> Observable<[DMEventSong]> {
        return authService
            .currentSessionObservable
            .flatMap { _ -> Observable<PagingObject<SavedTrack>> in
                return Observable<PagingObject<SavedTrack>>.create { observer -> Disposable in
                    _ = Spartan.getSavedTracks(offset: 20, market: Spartan.currentCountryCode, success: { pagingObject in
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
