//
//  Scene.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import UIKit

enum Scene {
    case rootNavigation
    case create(DMEventCreationViewModel)
    case search(DMEventSearchViewModel)
    case selectFlow(DMFlowSelectionViewModel)
}

extension Scene {
    func viewController() -> UIViewController {
        switch self {
        case .rootNavigation:
            let navigationController = UINavigationController()
            navigationController.navigationBar.prefersLargeTitles = true
            return navigationController
        case .create(let viewModel):
            let eventCreationVC = DMEventCreationViewController(withViewModel: viewModel)
            eventCreationVC.setupForViewModel()
            return eventCreationVC
        case .search(let viewModel):
            let eventSearchVC = DMEventSearchViewController(withViewModel: viewModel)
            eventSearchVC.setupForViewModel()
            return eventSearchVC
        case .selectFlow(let viewModel):
            let flowSelectionVC = DMFlowSelectionViewController(withViewModel: viewModel)
            flowSelectionVC.setupForViewModel()
            return flowSelectionVC
        }
    }
}
