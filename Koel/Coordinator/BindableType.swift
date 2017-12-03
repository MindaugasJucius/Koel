//
//  BindableType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift

protocol BindableType {
    associatedtype ViewModelType
    
    var viewModel: ViewModelType! { get set }
    
    init(withViewModel viewModel: ViewModelType)
    
    func bindViewModel()
}

extension BindableType where Self: UIViewController {
        
    func setupForViewModel() {
        loadViewIfNeeded()
        bindViewModel()
    }
}
