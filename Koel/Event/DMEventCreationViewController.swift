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
import MultipeerConnectivity

class DMEventCreationViewController: UIViewController {

    private var viewModel: DMEventCreationViewModel
    
    private let tableView = UITableView()
    private var advertiseButton = UIButton(type: .system)
    private var browseButton = UIButton(type: .system)
    
    private var bag = DisposeBag()
    
    init(withCreationViewModel viewModel: DMEventCreationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        viewModel.allPeers.bind(to: tableView.rx.items) { (tableView: UITableView, index: Int, element: PeerWithContext) in
            let path = IndexPath(item: index, section: 0)
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: path)
            cell.textLabel?.text = element.0.displayName
            return cell
        }.disposed(by: bag)
        
        viewModel.connectedPeers.subscribe(onNext: { [unowned self] peerIDs in
            let alert = UIAlertController(title: "New connection", message: "connected to \(peerIDs.map { $0.displayName })", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        }).disposed(by: bag)
        
        tableView.rx.itemSelected
            .map { [unowned self] indexPath in
                let peerWithContext: PeerWithContext = try! self.tableView.rx.model(at: indexPath)
                return (peerWithContext.0, nil)
            }
            .subscribe(viewModel.inviteAction.inputs)
            .disposed(by: bag)
        
        viewModel.incommingInvitations.subscribe(onNext: { invitation in
                let alert = UIAlertController(title: "Connection request", message: "connect to \(invitation.0.displayName)?", preferredStyle: .alert)
                let connectAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
                    let invitationHandler = invitation.2
                    invitationHandler(true)
                })
                alert.addAction(connectAction)
                self.present(alert, animated: true, completion: nil)
            }
        ).disposed(by: bag)
        
        let constraints = [tableView.topAnchor.constraint(equalTo: view.topAnchor),
                           tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
                           tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                           tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        NSLayoutConstraint.activate(constraints)
        
        advertiseButton.setTitle("advertise", for: .normal)
        browseButton.setTitle("browse", for: .normal)
        
        view.addSubview(advertiseButton)
        advertiseButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(browseButton)
        browseButton.translatesAutoresizingMaskIntoConstraints = false

        
        let browseButtonConstraints = [
            browseButton.leftAnchor.constraint(equalTo: view.leftAnchor),
            browseButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        
        let advertiseButtonConstraints = [
            advertiseButton.rightAnchor.constraint(equalTo: view.rightAnchor),
            advertiseButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(browseButtonConstraints)
        NSLayoutConstraint.activate(advertiseButtonConstraints)
        
        advertiseButton.rx.action = viewModel.onStartAdvertising()
        browseButton.rx.action = viewModel.onStartBrowsing()
        
        
    }

}
