//
//  DMKoelLoadingView.swift
//  Koel
//
//  Created by Mindaugas Jucius on 6/16/18.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class DMKoelLoadingView: UIView, Themeable {
    
    static let height: CGFloat = 50
    static let frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 50)
    
    private let disposeBag = DisposeBag()
    
    let themeManager: ThemeManager
    
    private lazy var activityControl: UIActivityIndicatorView = {
        let activityControl = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityControl.translatesAutoresizingMaskIntoConstraints = false
        return activityControl
    }()

    var isAnimating: Binder<Bool> {
        get {
            return activityControl.rx.isAnimating
        }
    }
    
    init(themeManager: ThemeManager) {
        self.themeManager = themeManager
        super.init(frame: DMKoelLoadingView.frame)
        backgroundColor = .lightGray
        
        addSubview(activityControl)
        let activityControlConstraints = [
            activityControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityControl.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        NSLayoutConstraint.activate(activityControlConstraints)
        
        bindThemeManager()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func bindThemeManager() {
        themeManager.currentTheme
            .map { $0.theme.backgroundColor }
            .drive(rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    
}

extension Reactive where Base: UIView {
    
    public var backgroundColor: Binder<UIColor> {
        return Binder(self.base) { view, color in
            view.backgroundColor = color
        }
    }
    
}
