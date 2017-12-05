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
    case create(DMEventInvitationsViewModel)
    case search(DMEventSearchViewModel)
    case selectFlow(DMFlowSelectionViewModel)
    case management(DMEventManagementViewModel)
}

extension Scene {
    func viewController() -> UIViewController {
        switch self {
        case .management(let viewModel):
            let eventManagementVC = DMEventManagementViewController(withViewModel: viewModel)
            eventManagementVC.setupForViewModel()

            let navigationController = UINavigationController(rootViewController: eventManagementVC)
            navigationController.navigationBar.prefersLargeTitles = true
            
            return navigationController
        case .rootNavigation:
            let navigationController = UINavigationController()
            navigationController.navigationBar.prefersLargeTitles = true
            return navigationController
        case .create(let viewModel):
            let eventCreationVC = DMEventInvitationsViewController(withViewModel: viewModel)
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
