//
//  DMEventManagementViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 06/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxDataSources
import RxCocoa
import RxSwift

class DMEventManagementViewController: UIViewController, BindableType {
    
    typealias ViewModelType = DMEventManagementViewModel

    private let disposeBag = DisposeBag()
    private let tableViewDataSource = DMEventManagementViewController.dataSource()
    
    var viewModel: DMEventManagementViewModel
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private lazy var invitationsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("invite", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        return button
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("add song", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        return button
    }()
    
    required init(withViewModel viewModel: DMEventManagementViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "manage"
        
        additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        view.backgroundColor = .white
        
        view.addSubview(invitationsButton)
        
        let invitationConstraints = [
            invitationsButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20),
            invitationsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        view.addSubview(addButton)
        
        let addButtonConstraints = [
            addButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        view.addSubview(tableView)
        
        let tableViewConstraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor)
        ]
        
        NSLayoutConstraint.activate(invitationConstraints)
        NSLayoutConstraint.activate(addButtonConstraints)
        NSLayoutConstraint.activate(tableViewConstraints)
    }
    
    func bindViewModel() {
        viewModel.songsSectioned
            .bind(to: tableView.rx.items(dataSource: tableViewDataSource))
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelSelected(DMEventSong.self)
            .filter { thing in
                thing.played == .none
            }
            .subscribe(viewModel.playedAction.inputs)
            .disposed(by: disposeBag)

        addButton.rx.action = viewModel.onSongCreate
        invitationsButton.rx.action = viewModel.onInvite()
    }
}

extension DMEventManagementViewController {
    
    static func dataSource() -> RxTableViewSectionedAnimatedDataSource<SongSection> {
        return RxTableViewSectionedAnimatedDataSource<SongSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .top, reloadAnimation: .fade, deleteAnimation: .left),
            configureCell: { (dataSource, tableView, indexPath, element) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                if let playedDate = element.played {
                    cell.textLabel?.text = "\(element.title) played \(playedDate)"
                } else {
                    cell.textLabel?.text = "\(element.title) added \(element.added)"
                }
                
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
            }
        )
    }
    
}
