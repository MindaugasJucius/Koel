//
//  DMFlowSelectionViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Action
import RxSwift

struct DMFlowSelectionViewModel: ViewModelType {
    
    let sceneCoordinator: SceneCoordinatorType
    private let spotifyService: DMSpotifyService
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType, spotifyService: DMSpotifyService) {
        self.spotifyService = spotifyService
        self.sceneCoordinator = sceneCoordinator
    }
    
    func onCreateEvent() -> CocoaAction {
        return CocoaAction { _ in

            let multipeerService = DMEventMultipeerService(
                withDisplayName: UIDevice.current.name,
                asEventHost: true
            )
            
            let songSharingViewModel = DMEventSongSharingViewModel(
                songPersistenceService: DMEventSongPersistenceService(),
                songSharingService: DMEventSongSharingService(),
                multipeerService: multipeerService
            )
            let manageEventViewModel = DMEventManagementViewModel(
                withSceneCoordinator: self.sceneCoordinator,
                multipeerService: multipeerService,
                songSharingViewModel: songSharingViewModel
            )
            
            return self.sceneCoordinator.transition(
                to: Scene.manage(manageEventViewModel),
                type: .rootWithNavigationVC
            )
        }
    }
    
    func onSpotifyLogin() -> CocoaAction {
        return CocoaAction { _ in
            self.spotifyService.performLoginIfNeeded()
            return Observable.empty()
        }
    }
    
    func onSearchEvent() -> CocoaAction {
        return CocoaAction { _ in
            let searchEventViewModel = DMEventSearchViewModel(withSceneCoordinator: self.sceneCoordinator)
            return self.sceneCoordinator.transition(
                to: Scene.search(searchEventViewModel),
                type: .rootWithNavigationVC
            )
        }
    }
    
}
