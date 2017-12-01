//
//  AppCoordinator.swift
//  Koel
//
//  Created by Mindaugas Jucius on 27/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import CloudKit

class AppCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController?

    var childCoordinators: [Coordinator] = []
    
    required init(withNavigationController navigationController: UINavigationController?) {
        self.navigationController = navigationController
        super.init()
        performInitialConfiguration()
    }
    
    func start() {
        let viewModel = DMEventCreationViewModel()
        let creation = DMEventCreationViewController(withCreationViewModel: viewModel)
        navigationController?.pushViewController(creation, animated: true)
//        if DMUserDefaultsHelper.CloudKitUserRecord == nil {
        
        //            let initialCoordinator = initialLoadingCoordinator()
//            initialCoordinator.start()
//        } else {
//            adjustToEventExistence()
//        }
    }
    
    private func performInitialConfiguration() {
        navigationController?.isNavigationBarHidden = true
    }
    
    // MARK: - Child Coordinator Creation
    
    private func initialLoadingCoordinator() -> DMInitialLoadingCoordinator {
        let coordinator = DMInitialLoadingCoordinator(withNavigationController: navigationController)
        coordinator.delegate = self
        childCoordinators.append(coordinator)
        return coordinator
    }
    
}

extension AppCoordinator: DMInitialLoadingCoordinatorDelegate {
    
    func initialLoadingSucceeded(withUser user: DMUser) {
        
    }
    
    func initialLoadingFailed(withError error: Error) {
        
    }
    
}
