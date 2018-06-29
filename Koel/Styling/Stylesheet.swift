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
        let titleAttributes = [NSAttributedStringKey.foregroundColor: UIColor.black,
                               NSAttributedStringKey.font : UIFont.systemFont(ofSize: 18, weight: .bold)]
        $0.titleTextAttributes = titleAttributes
    }
    
}

enum SongCellStylesheet {
    
    static let titleLabelStyle = Style<UILabel> {
        $0.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        $0.numberOfLines = 1
    }
    
    static let subtitleLabelStyle = Style<UILabel> {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.numberOfLines = 1
    }
    
}

