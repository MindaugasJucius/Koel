//
//  KoelPageViewController.swift
//  Koel
//
//  Created by Mindaugas on 30/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import RxCocoa
import RxSwift

import Foundation

class KoelPageViewController: UIPageViewController, Themeable {
    
    let themeManager: ThemeManager
    
    private let disposeBag = DisposeBag()
    private let statusBarStyleRelay = BehaviorRelay(value: UIStatusBarStyle.default)
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyleRelay.value
    }
    
    init(themeManager: ThemeManager) {
        self.themeManager = themeManager
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        bindThemeManager()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindThemeManager() {
        themeManager.currentTheme.do(onNext: { [unowned self] themeType in
                self.view.backgroundColor = themeType.theme.backgroundColor
            })
            .map { $0 == .light ? UIStatusBarStyle.default : UIStatusBarStyle.lightContent }
            .drive(statusBarStyleRelay)
            .disposed(by: disposeBag)
    }
    
}
