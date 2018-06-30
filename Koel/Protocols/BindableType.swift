//
//  BindableType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift

enum Result<T, E: Error> {
    case success(T)
    case failure(E)
}

protocol BindableType {
    associatedtype ViewModelType
    
    var viewModel: ViewModelType { get }
    
    func bindViewModel()
}

extension BindableType where Self: UIViewController {
        
    func setupForViewModel() {
        loadViewIfNeeded()
        bindViewModel()
    }
}
