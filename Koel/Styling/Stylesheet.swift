//
//  Stylesheet.swift
//  Koel
//
//  Created by Mindaugas Jucius on 18/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

private let isiPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad

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
        let titleStyle: UIFontTextStyle = isiPad ? .title2 : .body
        $0.font = UIFont.preferredFont(forTextStyle: titleStyle)
        $0.numberOfLines = 1
    }
    
    static let subtitleLabelStyle = Style<UILabel> {
        let titleStyle: UIFontTextStyle = isiPad ? .headline : .callout
        $0.font = UIFont.preferredFont(forTextStyle: titleStyle)
        $0.numberOfLines = 1
    }
    
}
