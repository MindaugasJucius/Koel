//
//  DMEventCreationViewController.swift
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

class DMEventCreationViewController: UIViewController, BindableType {
        
    var viewModel: DMEventCreationViewModel
    
    private let tableViewDataSource = DMEventCreationViewController.dataSource()
    private let tableView = UITableView()
    
    private var bag = DisposeBag()
    
    required init(withViewModel viewModel: DMEventCreationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "create"

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        let constraints = [tableView.topAnchor.constraint(equalTo: view.topAnchor),
                           tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
                           tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                           tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(constraints)
    }
    
    func bindViewModel() {
        viewModel.incommingParticipantInvitations
            .subscribe(onNext: { invitation in
                let alert = UIAlertController(title: "Connection request", message: "\(invitation.0.peerDeviceDisplayName) wants to join your party", preferredStyle: .alert)
                let connectAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
                    let invitationHandler = invitation.1
                    invitationHandler(true)
                })
                alert.addAction(connectAction)
                self.present(alert, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        viewModel.allPeersSectioned
            .bind(to: tableView.rx.items(dataSource: tableViewDataSource))
            .disposed(by: bag)
        
        viewModel.latestConnectedPeer
            .subscribe(onNext: { [unowned self] eventPeer in
                let alert = UIAlertController(title: "New connection", message: "connected to \(eventPeer.peerDeviceDisplayName)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        tableView.rx
            .modelSelected(DMEventPeer.self)
            .filter { !$0.isConnected }
            .subscribe(viewModel.inviteAction.inputs)
            .disposed(by: bag)
    }
}

extension DMEventCreationViewController {
    
    static func dataSource() -> RxTableViewSectionedAnimatedDataSource<EventPeerSection> {
        return RxTableViewSectionedAnimatedDataSource<EventPeerSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .top, reloadAnimation: .fade, deleteAnimation: .left),
            configureCell: { (dataSource, tableView, indexPath, element) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = element.peerDeviceDisplayName
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
            }
        )
    }
    
}
