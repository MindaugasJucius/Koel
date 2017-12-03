//
//  ViewModelType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Action

protocol ViewModelType {
    
    var sceneCoordinator: SceneCoordinatorType { get }
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType)
    
}

extension ViewModelType {
    
    func popController() -> CocoaAction {
        return CocoaAction {
            return self.sceneCoordinator.pop(animated: true)
        }
    }
    
}
