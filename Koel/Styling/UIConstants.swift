//
//  UIConstants.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

struct UIConstants {
    
    struct colors {

        static let primaryKoelPink = UIColor(red: 235/255, green: 2/255, blue: 141/255, alpha: 1)
        static let primaryKoelBlue = UIColor.colorWithHexString(hex: "19B5FE")
        
        struct logoView {
            static let firstScaleLayerColor = primaryKoelBlue.withAlphaComponent(0.4).cgColor
            static let secondScaleLayerColor = primaryKoelBlue.withAlphaComponent(0.6).cgColor
            
            static let gradientStartColor = UIColor.colorWithHexString(hex: "00dbde").cgColor
            static let gradientEndColor = UIColor.colorWithHexString(hex: "fc00ff").cgColor
        }
        
    }
    
}
