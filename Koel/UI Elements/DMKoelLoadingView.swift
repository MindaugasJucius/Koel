//
//  DMKoelLoadingView.swift
//  Koel
//
//  Created by Mindaugas Jucius on 6/16/18.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxCocoa

class DMKoelLoadingView: UIView {

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
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNormalMagnitude, height: 50))
        backgroundColor = .lightGray
        
        addSubview(activityControl)
        let activityControlConstraints = [
            activityControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityControl.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        NSLayoutConstraint.activate(activityControlConstraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
