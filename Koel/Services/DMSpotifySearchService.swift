//
//  DMSpotifySearchService.swift
//  Koel
//
//  Created by Mindaugas on 25/03/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation

protocol DMSpotifySearchServiceType {
    
    var authService: DMSpotifyAuthService { get }
    
}

struct DMSpotifySearchService: DMSpotifySearchServiceType {
    
    var authService: DMSpotifyAuthService
    
}
