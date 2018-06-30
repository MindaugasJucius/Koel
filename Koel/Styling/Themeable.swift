//
//  Themeable.swift
//  Koel
//
//  Created by Mindaugas on 30/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import RxSwift

protocol Themeable {
    
    var themeManager: ThemeManager { get }

    func bindThemeManager()
}

extension Themeable where Self: UIViewController {
    
    func themeNavigationBar() -> Observable<Void> {
        return rx.methodInvoked(#selector(viewWillAppear))
            .flatMap { _ in return self.themeManager.currentTheme }
            .do(onNext: { theme in
                self.navigationController?.navigationBar.apply(theme.navigationBarColors())
            })
            .map { _ in}
    }
    
    func themeViewColors() -> Observable<Void> {
        return themeManager.currentTheme
            .do(onNext: { [unowned self] theme in
                self.view.apply(theme.viewColors())
            })
            .map { _ in}
    }
    
}
