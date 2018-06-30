//
//  ThemeManager.swift
//  Koel
//
//  Created by Mindaugas on 29/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import RxCocoa
import RxSwift

private let koelPink = UIColor.colorWithHexString(hex: "EB028D")
private let koelDisabled = UIColor.colorWithHexString(hex: "BDC3C7")
private let koelBackground = UIColor.colorWithHexString(hex: "FCFCFC")

private let koelDarkText = UIColor.colorWithHexString(hex: "14110E")
private let koelLightText = UIColor.colorWithHexString(hex: "FCFCFC")

private let koelTint = UIColor.colorWithHexString(hex: "268CFF")

struct Theme {
    let primaryActionColor: UIColor
    let secondaryActionColor: UIColor
    let disabledColor: UIColor
    let primaryTextColor: UIColor
    let secondaryTextColor: UIColor
    let tintColor: UIColor
    let backgroundColor: UIColor
    
    static let light = Theme(primaryActionColor: koelPink,
                             secondaryActionColor: koelTint,
                             disabledColor: koelDisabled,
                             primaryTextColor: koelDarkText,
                             secondaryTextColor: koelLightText,
                             tintColor: koelTint,
                             backgroundColor: koelBackground)

    static let dark = Theme(primaryActionColor: koelPink,
                            secondaryActionColor: koelTint,
                            disabledColor: koelDisabled,
                            primaryTextColor: koelLightText,
                            secondaryTextColor: koelDarkText,
                            tintColor: koelTint,
                            backgroundColor: koelDarkText)
    
    
    func navigationBarColors() -> Style<UINavigationBar> {
        let style = Style<UINavigationBar> {
            let attributes = [NSAttributedStringKey.foregroundColor: self.primaryTextColor]
            $0.tintColor = self.tintColor
            $0.barTintColor = self.backgroundColor
            $0.largeTitleTextAttributes = attributes
            $0.titleTextAttributes = attributes
        }
        return style
    }

    func viewColors() -> Style<UIView> {
        let style = Style<UIView> {
            $0.tintColor = self.tintColor
            $0.backgroundColor = self.backgroundColor
        }
        return style
    }
    
}

class ThemeManager {
    
    static let shared = ThemeManager()
    
    private let currentThemeRelay = BehaviorRelay(value: Theme.dark)
    
    var themeValue: Theme {
        return currentThemeRelay.value
    }
    
    var currentTheme: Observable<Theme> {
        return currentThemeRelay.asObservable().share()
    }
    
}
