//
//  DMEventManagementViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 06/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

class DMEventManagementViewController: UIViewController, BindableType {
    
    typealias ViewModelType = DMEventManagementViewModel

    var viewModel: DMEventManagementViewModel
    
    required init(withViewModel viewModel: DMEventManagementViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func bindViewModel() {
        
    }
}
