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

    static let height: CGFloat = 50
    static let frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 50)
    
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
        super.init(frame: DMKoelLoadingView.frame)
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
