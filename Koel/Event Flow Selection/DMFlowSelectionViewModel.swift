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
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
    }
    
    func onCreateEvent() -> CocoaAction {
        return CocoaAction { _ in
            let manageEventViewModel = DMEventManagementViewModel(withSceneCoordinator: self.sceneCoordinator)
            return self.sceneCoordinator.transition(
                to: Scene.manage(manageEventViewModel),
                type: .rootWithNavigationVC
            )
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
