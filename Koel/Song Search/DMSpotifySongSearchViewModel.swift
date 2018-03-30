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
    
    var searchAction: CocoaAction  { get }
}

struct DMSpotifySongSearchViewModel: DMSpotifySongSearchViewModelType {
    
    var sceneCoordinator: SceneCoordinatorType
    var spotifySearchService: DMSpotifySearchServiceType
    
    let searchAction: CocoaAction
    
    init(sceneCoordinator: SceneCoordinatorType, spotifySearchService: DMSpotifySearchServiceType) {
        self.sceneCoordinator = sceneCoordinator
        self.spotifySearchService = spotifySearchService
       
        self.searchAction = CocoaAction(workFactory: { () -> Observable<Void> in
            return spotifySearchService.savedTracks().map { _ in }
        })
        
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
