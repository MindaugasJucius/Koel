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
    
    func playlists() -> Observable<Void>
    func savedTracks() -> Observable<[DMEventSong]>
    
}

class DMSpotifySearchService: DMSpotifySearchServiceType {
    
    var authService: DMSpotifyAuthService
    
    init(authService: DMSpotifyAuthService) {
        self.authService = authService
    }
  
    func playlists() -> Observable<Void> {
        
        return authService
            .currentSessionObservable
            .map { [unowned self] session in
                _ = Spartan.getUsersPlaylists(userId: session.canonicalUsername, limit: 20, offset: 0, success: { (pagingObject) in
                    print(pagingObject.toJSONString(prettyPrint: true))
                    // Get the playlists via pagingObject.playlists
                }, failure: { (error) in
                    print(error)
                })
            }
    }
    
    func savedTracks() -> Observable<[DMEventSong]> {
        return authService
            .currentSessionObservable
            .flatMap { _ -> Observable<PagingObject<SavedTrack>> in
                return Observable<PagingObject<SavedTrack>>.create { observer -> Disposable in
                    _ = Spartan.getSavedTracks(market: Spartan.currentCountryCode, success: { pagingObject in
                        observer.onNext(pagingObject)
                    }, failure: { error in
                        if let error = error.nsError {
                            observer.onError(error)
                        }
                    })
                    return Disposables.create()
                }
            }
            .map { pagingObject -> [DMEventSong] in
                return pagingObject.items.map { savedTrack -> DMEventSong in
                    let eventSong = DMEventSong()
                    eventSong.spotifyURI = savedTrack.track.uri
                    eventSong.title = "\(savedTrack.track.album.artists[0].name) - \(savedTrack.track.name)"
                    return eventSong
                }
            }.do(onNext: { songs in
                print(songs)
            })
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
