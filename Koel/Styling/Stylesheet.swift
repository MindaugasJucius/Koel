//
//  Stylesheet.swift
//  Koel
//
//  Created by Mindaugas Jucius on 18/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

enum DefaultStylesheet {
    
    static let navigationBarStyle = Style<UINavigationBar> {
        let gradientColors = [UIConstants.colors.koelPurple, UIConstants.colors.koelSkyBlue]
        let titleAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        let gradientLayer = CAGradientLayer(frame: $0.bounds, colorsForNavigationBar: gradientColors)
        if let gradientImage = gradientLayer.createImage() {
            $0.barTintColor = UIColor(patternImage: gradientImage)
        }
        
        $0.prefersLargeTitles = true
        $0.largeTitleTextAttributes = titleAttributes
        $0.titleTextAttributes = titleAttributes
        $0.barStyle = .black
    }

}

enum SongCellStylesheet {
    
    static let titleLabelStyle = Style<UILabel> {
        $0.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        $0.numberOfLines = 1
    }
    
    static let subtitleLabelStyle = Style<UILabel> {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        $0.numberOfLines = 1
    }
    
}

