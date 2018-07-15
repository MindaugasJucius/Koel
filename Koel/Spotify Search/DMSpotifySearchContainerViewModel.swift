//
//  DMSpotifySearchContainerViewModel.swift
//  Koel
//
//  Created by Mindaugas on 15/07/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import Action
import RxSwift

protocol DMSpotifySearchContainerViewModelType {
    
    var reachability: Observable<ReachabilityStatus> { get }
    
}

class DMSpotifySearchContainerViewModel: NSObject, DMSpotifySearchContainerViewModelType {
    
    let reachabilityService: ReachabilityService
    let spotifyAuthService: DMSpotifyAuthService
    let onQueueSelectedSongs: Action<[DMSearchResultSong], Void>
    
    var reachability: Observable<ReachabilityStatus> {
        return reachabilityService.reachability
    }
    
    init(reachabilityService: ReachabilityService,
         spotifyAuthService: DMSpotifyAuthService,
         onQueueSelectedSongs: Action<[DMSearchResultSong], Void>) {
        self.reachabilityService = reachabilityService
        self.spotifyAuthService = spotifyAuthService
        self.onQueueSelectedSongs = onQueueSelectedSongs
    }
    
}
