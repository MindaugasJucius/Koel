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
    
    
    init(withViewModelOfType viewModel: DMInitialLoadingViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let subscription = viewModel.userObservable?.subscribe(
            { user in
                
            }
        )
        
    }
    
}
