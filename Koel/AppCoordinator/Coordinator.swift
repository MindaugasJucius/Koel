//
//  Coordinator.swift
//  Koel
//
//  Created by Mindaugas Jucius on 27/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

protocol Coordinator: class {
    weak var navigationController: UINavigationController? { get }
    var childCoordinators: [Coordinator] { get }
    
    init(withNavigationController navigationController: UINavigationController?)

    func start()
}
