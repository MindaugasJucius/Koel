//
//  DMSpotifySongSearchViewModel.swift
//  Koel
//
//  Created by Mindaugas on 25/03/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Action
import RxSwift

protocol DMSpotifySongSearchViewModelType: ViewModelType {
    
    var spotifySearchService: DMSpotifySearchServiceType { get }
    
    var searchResults: Observable<[SongSection]> { get }
}

class DMSpotifySongSearchViewModel: DMSpotifySongSearchViewModelType {
    
    var sceneCoordinator: SceneCoordinatorType
    var spotifySearchService: DMSpotifySearchServiceType

    lazy var searchResults: Observable<[SongSection]> = {
        return spotifySearchService.savedTracks().map { songs in
            [SongSection(model: "Results", items: songs)]
        }
    }()
    
    init(sceneCoordinator: SceneCoordinatorType, spotifySearchService: DMSpotifySearchServiceType) {
        self.sceneCoordinator = sceneCoordinator
        self.spotifySearchService = spotifySearchService
        
        //spotifySearchService.authService.currentSession.subscribe(onNext: <#T##((SPTSession) -> Void)?##((SPTSession) -> Void)?##(SPTSession) -> Void#>, onError: <#T##((Error) -> Void)?##((Error) -> Void)?##(Error) -> Void#>, onCompleted: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>, onDisposed: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>)
        
//        if spotifySearchService.authService.authenticationIsNeeded {
//            spotifySearchService.authService.performAuthentication()
//        }
    }
    
    
//    lazy var inviteAction: Action<(DMEventPeer), Void> = { this in
//        return Action(
//            workFactory: { (eventPeer: DMEventPeer) in
//                let hostContext = ContextKeys.isHost.dictionary
//                return this.multipeerService.connect(eventPeer.peerID, context: hostContext)
//        }
//        )
//    }(self)
    
}
