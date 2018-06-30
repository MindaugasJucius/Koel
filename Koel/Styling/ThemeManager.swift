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

enum ThemeType {
    case light
    case dark
    
    var theme: Theme {
        switch self {
        case .dark:
            return Theme.dark
        case .light:
            return Theme.light
        }
    }
}

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

    static let dark = Theme(primaryActionColor: koelTint,
                            secondaryActionColor: koelPink,
                            disabledColor: koelDisabled,
                            primaryTextColor: koelLightText,
                            secondaryTextColor: koelDarkText,
                            tintColor: koelTint,
                            backgroundColor: koelDarkText)
}

class ThemeManager {
    
    static let shared = ThemeManager()
    
    private let currentThemeRelay = BehaviorRelay(value: ThemeType.light)

    
    var themeValue: ThemeType {
        return currentThemeRelay.value
    }
    
    var currentTheme: Driver<ThemeType> {
        return currentThemeRelay.asDriver()
    }
    
}
