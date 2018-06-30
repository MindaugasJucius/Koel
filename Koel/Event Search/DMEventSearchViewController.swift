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

class DMEventSearchViewController: UIViewController, BindableType, Themeable {
    
    typealias ViewModelType = DMEventSearchViewModel
    
    private let disposeBag = DisposeBag()
    let viewModel: DMEventSearchViewModel
    let themeManager: ThemeManager
    
    //MARK: UI
    private var startEventButton: DMKoelButton
    private let tableView = UITableView()
        
    init(withViewModel viewModel: DMEventSearchViewModel, themeManager: ThemeManager) {
        self.themeManager = themeManager
        self.viewModel = viewModel
        self.startEventButton = DMKoelButton(themeManager: themeManager)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        navigationController?.navigationBar.apply(DefaultStylesheet.largeNavigationBarStyle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = UIConstants.strings.searchScreenTitle
        bindThemeManager()
        
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.readableContentGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.readableContentGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
        view.addSubview(startEventButton)
        startEventButton.addConstraints(inSuperview: view)
        startEventButton.setTitle(UIConstants.strings.searchScreenButtonStartEventTitle, for: .normal)
    }
    
    func bindViewModel() {
        viewModel.incommingInvitations
            .subscribe(onNext: { invitation in
                let alert = UIAlertController(title: "Connection request", message: "Join \(invitation.0.peerID?.displayName)'s event?", preferredStyle: .alert)
                let connectAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
                    let invitationHandler = invitation.1
                    invitationHandler(true)
                })
                alert.addAction(connectAction)
                self.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        viewModel.hosts
            .bind(to: tableView.rx.items) { (tableView: UITableView, index: Int, element: DMEventPeer) in
                let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
                cell.textLabel?.text = element.peerID?.displayName
                return cell
            }
            .disposed(by: disposeBag)
        
        startEventButton.rx.action = viewModel.pushEventManagement
        
        tableView.rx
            .modelSelected(DMEventPeer.self)
            .filter { !$0.isConnected }
            .subscribe(viewModel.requestAccess.inputs)
            .disposed(by: disposeBag)
    }
    
    func bindThemeManager() {
        themeNavigationBar()
            .drive()
            .disposed(by: disposeBag)
        
        themeViewColors()
            .drive()
            .disposed(by: disposeBag)
    }
    
}
