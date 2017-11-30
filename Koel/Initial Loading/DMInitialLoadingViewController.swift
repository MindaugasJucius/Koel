//
//  DMInitialLoadingViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/19/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift

class DMInitialLoadingViewController: UIViewController {

    let viewModel: DMInitialLoadingViewModelType

    let logoView = DMKoelLogoView()
    
    let bag = DisposeBag()
    
    init(withViewModelOfType viewModel: DMInitialLoadingViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logoView.startAnimating()
    }

    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(logoView)
        let constraints = [
            logoView.widthAnchor.constraint(equalToConstant: DMKoelLogoView.Height),
            logoView.heightAnchor.constraint(equalToConstant: DMKoelLogoView.Height),
            logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
        let koel = "koel"
        
        let koelLabel = UILabel()
        let attributedString = NSMutableAttributedString(string: koel)
        attributedString.addAttribute(NSAttributedStringKey.kern, value: CGFloat(-1.4), range: NSRange(location: 0, length: koel.count))
        attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont(name: "HelveticaNeue-Thin", size: 64)!, range: NSRange(location: 0, length: koel.count))
        
        koelLabel.attributedText = attributedString
        koelLabel.textColor = .white
        
        koelLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(koelLabel)
        
        let labelConstraints = [
            koelLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            koelLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 60)
        ]
        
        NSLayoutConstraint.activate(labelConstraints)
    }
    
}
