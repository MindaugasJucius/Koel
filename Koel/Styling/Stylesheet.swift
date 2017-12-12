//
//  Stylesheets.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

enum FlowSelectionStylesheet {

    static let buttonStart = Style<UIButton> { buttonToStyle in
        
    }
    
    static let buttonEnd = Style<UIButton> { buttonToStyle in
        
    }
    
    static let title = Style<UILabel> {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .red
        $0.numberOfLines = 2
    }
    
    static let image = Style<UIImageView> {
        $0.contentMode = .center
        $0.backgroundColor = .darkGray
    }

}
