//
//  DMEventManagementViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 04/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class DMEventParticipationViewController: UIViewController, BindableType {

    typealias ViewModelType = DMEventParticipantViewModel
    
    var viewModel: DMEventParticipantViewModel

    private let disposeBag = DisposeBag()
    
    //MARK: UI
    
    private let label = UILabel()
    
    required init(withViewModel viewModel: DMEventParticipantViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "participate"
        
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        let constraints = [
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func bindViewModel() {
        viewModel
            .hostExists
            .map { $0 ? "host exists" : "host disconnected" }
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
    }

}
