//
//  DMInitialLoadingCoordinator.swift
//  Koel
//
//  Created by Mindaugas Jucius on 27/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

class DMInitialLoadingCoordinator: NSObject, Coordinator {
    
    var navigationController: UINavigationController?
    var childCoordinators: [Coordinator] = []
        
    required init(withNavigationController navigationController: UINavigationController?) {
        self.navigationController = navigationController
        super.init()
    }
    
    func start() {
    
        let initialLoadingViewController = DMInitialLoadingViewController()
        
        navigationController?.present(initialLoadingViewController, animated: false, completion: nil)
    }

}
