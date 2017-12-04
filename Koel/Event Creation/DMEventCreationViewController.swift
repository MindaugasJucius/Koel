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
                return peerWithContext
            }
            .subscribe(viewModel.inviteAction.inputs)
            .disposed(by: bag)
    }
    

}
