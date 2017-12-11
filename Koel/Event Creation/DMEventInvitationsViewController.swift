//
//  DMEventInvitationsViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 01/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxCocoa
import Action
import RxSwift
import RxDataSources

class DMEventInvitationsViewController: UIViewController, BindableType {
        
    var viewModel: DMEventInvitationsViewModel
    
    private let tableViewDataSource = DMEventInvitationsViewController.dataSource()
    private let tableView = UITableView()
    
    private var bag = DisposeBag()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("done", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        return button
    }()
    
    required init(withViewModel viewModel: DMEventInvitationsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "invite"
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        let tableViewConstraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 30)
        ]
        
        NSLayoutConstraint.activate(tableViewConstraints)
    
        view.addSubview(doneButton)
        
        let buttonConstraints = [
            doneButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(buttonConstraints)
    }
    
    func bindViewModel() {
        doneButton.rx.action = viewModel.onClose
        
        viewModel.allPeersSectioned
            .bind(to: tableView.rx.items(dataSource: tableViewDataSource))
            .disposed(by: bag)
        
        tableView.rx
            .modelSelected(DMEventPeer.self)
            .filter { !$0.isConnected }
            .subscribe(viewModel.inviteAction.inputs)
            .disposed(by: bag)
    }
}

extension DMEventInvitationsViewController {
    
    static func dataSource() -> RxTableViewSectionedAnimatedDataSource<EventPeerSection> {
        return RxTableViewSectionedAnimatedDataSource<EventPeerSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .top, reloadAnimation: .fade, deleteAnimation: .left),
            configureCell: { (dataSource, tableView, indexPath, element) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = element.peerID?.displayName
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
            }
        )
    }
    
}
