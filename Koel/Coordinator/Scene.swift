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
    case create(DMEventCreationViewModel)
    case join(DMEventSearchViewModel)
}


extension Scene {
    func viewController() -> UIViewController {
        switch self {
        case .create(let viewModel):
            let eventCreationVC = DMEventCreationViewController(withCreationViewModel: viewModel)
            eventCreationVC.setupForViewModel()
            return eventCreationVC
        case .join(let viewModel):
            print("lul")
        }
        return UIViewController()
    }
}
