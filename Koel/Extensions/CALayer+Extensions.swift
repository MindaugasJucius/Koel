//
//  CALayer+Extensions.swift
//  Koel
//
//  Created by Mindaugas Jucius on 18/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

extension CALayer {
    
    func createImage() -> UIImage? {
        UIGraphicsBeginImageContext(bounds.size)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        defer {
            UIGraphicsEndImageContext()
        }

        render(in: context)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
}
