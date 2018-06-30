//
//  Themeable.swift
//  Koel
//
//  Created by Mindaugas on 30/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import RxSwift
import RxCocoa

protocol Themeable {
    
    var themeManager: ThemeManager { get }

    func bindThemeManager()
}

extension Themeable where Self: UIViewController {
    
    func themeNavigationBar() -> Driver<Void> {
        return rx.methodInvoked(#selector(viewWillAppear)).asSignal(onErrorJustReturn: [])
            .flatMap { _ in return self.themeManager.currentTheme }
            .do(onNext: { themeType in
                let navigationBarStyle = ThemeStylesheet.navigationBarColors(forThemeType: themeType)
                self.navigationController?.navigationBar.apply(navigationBarStyle)
            })
            .map { _ in}
    }
    
    func themeViewColors() -> Driver<Void> {
        return themeManager.currentTheme
            .do(onNext: { [unowned self] themeType in
                let viewColorsStyle = ThemeStylesheet.viewColors(forThemeType: themeType)
                self.view.apply(viewColorsStyle)
            })
            .map { _ in}
    }
    
}
