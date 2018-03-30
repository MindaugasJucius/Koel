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
    func savedTracks() -> Observable<Void>
    
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
    
    func savedTracks() -> Observable<Void> {
        return authService
            .currentSessionObservable
            .map { [unowned self] session in
                _ = Spartan.getSavedTracks(limit: 20, offset: 0, market: Spartan.currentCountryCode, success: { (pagingObject) in
                    print(pagingObject.toJSONString(prettyPrint: true))
                    // Get the saved tracks via pagingObject.items
                }, failure: { (error) in
                    print(error)
                })
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
