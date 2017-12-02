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
        
        viewModel.allPeers.bind(to: tableView.rx.items) { (tableView: UITableView, index: Int, element: DMEventPeer) in
            let path = IndexPath(item: index, section: 0)
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: path)
            cell.textLabel?.text = element.peerDeviceDisplayName
            return cell
        }.disposed(by: bag)
        
        viewModel.latestConnectedPeer.subscribe(onNext: { [unowned self] eventPeer in
            let alert = UIAlertController(title: "New connection", message: "connected to \(eventPeer.peerDeviceDisplayName)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }).disposed(by: bag)
        
        tableView.rx.itemSelected
            .map { [unowned self] indexPath in
                let peerWithContext: DMEventPeer = try! self.tableView.rx.model(at: indexPath)
                return (peerWithContext, nil)
            }
            .subscribe(viewModel.inviteAction.inputs)
            .disposed(by: bag)
        
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
        
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
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
            browseButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant:         view.safeAreaInsets.left),
            browseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        let advertiseButtonConstraints = [
            advertiseButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: view.safeAreaInsets.right),
            advertiseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(browseButtonConstraints)
        NSLayoutConstraint.activate(advertiseButtonConstraints)
        
        advertiseButton.rx.action = viewModel.onStartAdvertising()
        browseButton.rx.action = viewModel.onStartBrowsing()
        
    }

}
