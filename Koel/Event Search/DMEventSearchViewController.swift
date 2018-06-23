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
    private var startEventButton = DMKoelButton()
    
    //MARK: UI
    private let tableView = UITableView()
    
    required init(withViewModel viewModel: DMEventSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        navigationController?.navigationBar.apply(DefaultStylesheet.navigationBarStyle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = UIConstants.strings.searchScreenTitle

        view.backgroundColor = .white
        navigationController?.navigationBar.apply(DefaultStylesheet.navigationBarStyle)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
        view.addSubview(startEventButton)
        startEventButton.addConstraints(inSuperview: view)
        startEventButton.setTitle(UIConstants.strings.searchScreenButtonStartEventTitle, for: .normal)
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
        
        startEventButton.rx.action = viewModel.pushEventManagement
        
        tableView.rx
            .modelSelected(DMEventPeer.self)
            .filter { !$0.isConnected }
            .subscribe(viewModel.requestAccess.inputs)
            .disposed(by: bag)
    }
    
}
