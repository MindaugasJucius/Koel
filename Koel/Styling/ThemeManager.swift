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
private let koelSelectedBackground = UIColor.colorWithHexString(hex: "EBF4FF")

private let koelDarkBackground = UIColor.colorWithHexString(hex: "14110E")
private let koelDarkSelectedBackground = UIColor.colorWithHexString(hex: "191D2A")

private let koelText = UIColor.colorWithHexString(hex: "14110E")
private let koelTextSecondary = UIColor.colorWithHexString(hex: "2D313D")

private let koelTextOnDark = UIColor.colorWithHexString(hex: "FCFCFC")
private let koelTextSecondaryOnDark = UIColor.colorWithHexString(hex: "BEBEBE")

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
    let selectedBackground: UIColor
    
    static let light = Theme(primaryActionColor: koelPink,
                             secondaryActionColor: koelTint,
                             disabledColor: koelDisabled,
                             primaryTextColor: koelText,
                             secondaryTextColor: koelTextSecondary,
                             tintColor: koelTint,
                             backgroundColor: koelBackground,
                             selectedBackground: koelSelectedBackground)

    static let dark = Theme(primaryActionColor: koelTint,
                            secondaryActionColor: koelPink,
                            disabledColor: koelDisabled,
                            primaryTextColor: koelTextOnDark,
                            secondaryTextColor: koelTextSecondaryOnDark,
                            tintColor: koelTint,
                            backgroundColor: koelDarkBackground,
                            selectedBackground: koelDarkSelectedBackground)
}

class ThemeManager {
    
    static let shared = ThemeManager()
    
    private let currentThemeRelay = BehaviorRelay(value: ThemeType.dark)
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
            let newTheme: ThemeType = self.themeValue == .light ? .dark : .light
            self.currentThemeRelay.accept(newTheme)
        }
    }
    
    var themeValue: ThemeType {
        return currentThemeRelay.value
    }
    
    var currentTheme: Driver<ThemeType> {
        return currentThemeRelay.asDriver()
    }
    
}
