//
//  DMFlowSelectionViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Action
import RxSwift

struct DMFlowSelectionViewModel {
    
    private let sceneCoordinator: SceneCoordinatorType
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
    }
    
    func onCreateEvent() -> CocoaAction {
        return CocoaAction { _ in
            let createEventViewModel = DMEventCreationViewModel(withSceneCoordinator: self.sceneCoordinator)
            createEventViewModel.onStartBrowsing()
            createEventViewModel.onStartAdvertising()
            return self.sceneCoordinator.transition(to: Scene.create(createEventViewModel), type: .push)
        }
    }
    
    func onSearchEvent() -> CocoaAction {
        return CocoaAction { _ in
            let searchEventViewModel = DMEventSearchViewModel(withSceneCoordinator: self.sceneCoordinator)
            searchEventViewModel.onStartAdvertising()
            searchEventViewModel.onStartBrowsing()
            return self.sceneCoordinator.transition(to: Scene.search(searchEventViewModel), type: .push)
        }
    }
    
}
