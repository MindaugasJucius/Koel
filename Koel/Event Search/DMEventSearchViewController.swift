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

class DMEventSearchViewController: UIViewController, BindableType {
    
    typealias ViewModelType = DMEventSearchViewModel
    
    var viewModel: DMEventSearchViewModel
    
    private var bag = DisposeBag()
    
    //MARK: UI
    private let tableView = UITableView()
    
    required init(withViewModel viewModel: DMEventSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "search for party hosts"

        view.backgroundColor = .white
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        let constraints = [tableView.topAnchor.constraint(equalTo: view.topAnchor),
                           tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
                           tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                           tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(constraints)
    }

    func bindViewModel() {
        viewModel.incommingInvitations
            .subscribe(onNext: { invitation in
                let alert = UIAlertController(title: "Connection request", message: "connect to \(invitation.0.peerID?.displayName)?", preferredStyle: .alert)
                let connectAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
                    let invitationHandler = invitation.1
                    invitationHandler(true)
                })
                alert.addAction(connectAction)
                self.present(alert, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        viewModel.hosts
            .bind(to: tableView.rx.items) { (tableView: UITableView, index: Int, element: DMEventPeer) in
                let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
                cell.textLabel?.text = element.peerID?.displayName
                return cell
            }
            .disposed(by: bag)
        
        tableView.rx
            .modelSelected(DMEventPeer.self)
            .filter { !$0.isConnected }
            .subscribe(viewModel.requestAccess.inputs)
            .disposed(by: bag)
    }
    
}
