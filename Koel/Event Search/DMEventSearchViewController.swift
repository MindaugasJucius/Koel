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
    
    var viewModel: DMEventSearchViewModel
    
    private var bag = DisposeBag()
    
    private var sendButton = UIButton(type: .system)
    
    required init(withViewModel viewModel: DMEventSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        sendButton.setTitle("send msg", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        let constraints = [
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
        title = "search"
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

        let eventHostObservable = viewModel
            .eventHost
            .asObservable()
        
        eventHostObservable
            .map { $0 == nil }
            .bind(to: sendButton.rx.isHidden)
            .disposed(by: bag)
        
        sendButton.rx.action = viewModel.sendMessage()
        
        eventHostObservable
            .skip(1)
            .subscribe(onNext: { [unowned self] eventPeer in
                guard let host = eventPeer else {
                    return
                }
                
                let alert = UIAlertController(title: "Joined", message: "Joined a Party hosted by \(host.peerDeviceDisplayName)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            })
            .disposed(by: bag)
    }
    
}
