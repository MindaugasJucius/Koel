//
//  UIViewController+Extensions.swift
//  Koel
//
//  Created by Mindaugas Jucius on 22/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

extension UIViewController {
    
    #if DEBUG
    @objc func injected() {
        _ = view.subviews.flatMap {
            $0.removeFromSuperview()
        }
        viewDidLoad()
    }
    #endif

}
