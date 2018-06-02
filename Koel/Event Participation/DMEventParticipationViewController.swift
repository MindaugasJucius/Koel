//
//  DMEventManagementViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 04/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources

class DMEventParticipationViewController: UIViewController, BindableType {

    typealias ViewModelType = DMEventParticipationViewModelType
    
    var viewModel: DMEventParticipationViewModelType

    private let disposeBag = DisposeBag()
    
    //MARK: UI
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(DMEventSongPersistedTableViewCell.self, forCellReuseIdentifier: DMEventSongPersistedTableViewCell.reuseIdentifier)
        return tableView
    }()
    
    private let tableViewDataSource: RxTableViewSectionedReloadDataSource<SongSection>
    
    private let label = UILabel()
    
    required init(withViewModel viewModel: DMEventParticipationViewModelType) {
        self.viewModel = viewModel
        self.tableViewDataSource = DMEventParticipationViewController.persistedSongDataSource(withViewModel: viewModel)
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
        view.backgroundColor = .white
        title = UIConstants.strings.participateTitle
        
        view.addSubview(tableView)
        let tableViewConstraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(tableViewConstraints)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        let constraints = [
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func bindViewModel() {
        viewModel
            .hostExists
            .map { $0 ? "host exists" : "host disconnected" }
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.songsSectioned
            .bind(to: tableView.rx.items(dataSource: tableViewDataSource))
            .disposed(by: disposeBag)
    }

}
