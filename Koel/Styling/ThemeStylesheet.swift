//
//  ThemeStylesheet.swift
//  Koel
//
//  Created by Mindaugas on 30/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit

enum ThemeStylesheet {

    static func navigationBarColors(forThemeType themeType: ThemeType) -> Style<UINavigationBar> {
        let theme = themeType.theme
        let style = Style<UINavigationBar> {
            let attributes = [NSAttributedStringKey.foregroundColor: theme.primaryTextColor]
            $0.tintColor = theme.tintColor
            $0.barTintColor = theme.backgroundColor
            $0.largeTitleTextAttributes = attributes
            $0.titleTextAttributes = attributes
            $0.barStyle = themeType == .light ? .default : .black
        }
        return style
    }
    
    static func viewColors(forThemeType themeType: ThemeType) -> Style<UIView> {
        let theme = themeType.theme
        let style = Style<UIView> {
            $0.tintColor = theme.tintColor
            $0.backgroundColor = theme.backgroundColor
        }
        return style
    }

}
