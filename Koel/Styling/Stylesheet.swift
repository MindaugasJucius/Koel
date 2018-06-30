//
//  Stylesheet.swift
//  Koel
//
//  Created by Mindaugas Jucius on 18/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

enum DefaultStylesheet {
    
    static let largeNavigationBarStyle = Style<UINavigationBar> {
        $0.prefersLargeTitles = true
    }
    
    static let navigationBarStyle = Style<UINavigationBar> {
        $0.prefersLargeTitles = false
    }
    
}

enum SongCellStylesheet {
    
    static let titleLabelStyle = Style<UILabel> {
        $0.font = UIFont.preferredFont(forTextStyle: .title2)
        $0.numberOfLines = 1
    }
    
    static let subtitleLabelStyle = Style<UILabel> {
        $0.font = UIFont.preferredFont(forTextStyle: .headline)
        $0.numberOfLines = 1
    }
    
}
