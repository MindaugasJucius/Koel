//
//  DMInitialLoadingCoordinator.swift
//  Koel
//
//  Created by Mindaugas Jucius on 27/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

protocol DMInitialLoadingCoordinatorDelegate: class {
    
    func initialLoadingSucceeded(withUser user: DMUser)
    func initialLoadingFailed(withError error: Error)
    
}

class DMInitialLoadingCoordinator: NSObject, Coordinator {
    
    var navigationController: UINavigationController?
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: DMInitialLoadingCoordinatorDelegate?
    
    required init(withNavigationController navigationController: UINavigationController?) {
        self.navigationController = navigationController
        super.init()
    }
    
    func start() {
        let initialFetchCompletion: InitialFetch = { user, error in
            if let user = user {
                self.delegate?.initialLoadingSucceeded(withUser: user)
            } else if let error = error {
                self.delegate?.initialLoadingFailed(withError: error)
            }
        }
        
        let initialLoadingViewModel = DMInitialLoadingViewModel(withInitialFetchCompletion: initialFetchCompletion)
        let initialLoadingViewController = DMInitialLoadingViewController(withViewModelOfType: initialLoadingViewModel)
        
        navigationController?.present(initialLoadingViewController, animated: false, completion: nil)
    }

}
