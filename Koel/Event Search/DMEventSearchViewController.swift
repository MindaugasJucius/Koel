//
//  DMEventSearchViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxCocoa
import Action
import RxSwift
import RxDataSources

class DMEventSearchViewController: UIViewController, BindableType {
    
    typealias ViewModelType = DMEventSearchViewModel
    
    var viewModel: DMEventSearchViewModel!
    
    private var bag = DisposeBag()
    
    required init(withViewModel viewModel: DMEventSearchViewModel) {
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
        viewModel.incommingInvitations.subscribe(onNext: { invitation in
            let alert = UIAlertController(title: "Connection request", message: "connect to \(invitation.0.peerDeviceDisplayName)?", preferredStyle: .alert)
            let connectAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
                let invitationHandler = invitation.1
                invitationHandler(true)
            })
            alert.addAction(connectAction)
            self.present(alert, animated: true, completion: nil)
        }
        ).disposed(by: bag)
    }
    
}
