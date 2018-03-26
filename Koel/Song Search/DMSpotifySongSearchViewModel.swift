//
//  DMSpotifySongSearchViewModel.swift
//  Koel
//
//  Created by Mindaugas on 25/03/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation

protocol DMSpotifySongSearchViewModelType: ViewModelType {
    
    var spotifySearchService: DMSpotifySearchServiceType { get }
    
}

struct DMSpotifySongSearchViewModel: DMSpotifySongSearchViewModelType {
    
    var sceneCoordinator: SceneCoordinatorType
    var spotifySearchService: DMSpotifySearchServiceType
    
    init(sceneCoordinator: SceneCoordinatorType, spotifySearchService: DMSpotifySearchServiceType) {
        self.sceneCoordinator = sceneCoordinator
        self.spotifySearchService = spotifySearchService
        
        if spotifySearchService.authService.authenticationIsNeeded {
            spotifySearchService.authService.performAuthentication()
        }
    }
    
}
