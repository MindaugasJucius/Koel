//
//  CAGradientLayer+Extensions.swift
//  Koel
//
//  Created by Mindaugas Jucius on 18/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

extension CAGradientLayer {
    
    convenience init(frame: CGRect, colorsForNavigationBar colors: [UIColor]) {
        self.init()
        self.frame = frame
        self.colors = colors.map { $0.cgColor }
        
        startPoint = CGPoint(x: 0, y: 0.5)
        endPoint = CGPoint(x: 1, y: 0.5)
    }
    
}
