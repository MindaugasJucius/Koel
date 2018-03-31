//
//  DMSpotifySongSearchViewController.swift
//  Koel
//
//  Created by Mindaugas on 25/03/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class DMSpotifySongSearchViewController: UIViewController, BindableType {
    
    typealias ViewModelType = DMSpotifySongSearchViewModelType

    var viewModel: DMSpotifySongSearchViewModelType

    private let disposeBag = DisposeBag()
    
    private lazy var searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Search", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(DMSpotifySongTableViewCell.self, forCellReuseIdentifier: DMSpotifySongTableViewCell.reuseIdentifier)
        return tableView
    }()
    
    required init(withViewModel viewModel: DMSpotifySongSearchViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        
        view.addSubview(tableView)
        
        let tableViewConstraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(tableViewConstraints)
        
        self.view.addSubview(searchButton)
        
        let buttonConstraints = [
            searchButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20),
            searchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(buttonConstraints)
    }
    
    func bindViewModel() {
        //
        rx.methodInvoked(#selector(UIViewController.viewDidAppear(_:)))
            .take(1)
            .do { [unowned self] in
                let dataSource = DMSpotifySongSearchViewController.persistedSongDataSource(withViewModel: self.viewModel)
                
                self.viewModel.searchResults
                    .bind(to: self.tableView.rx.items(dataSource: dataSource))
                    .disposed(by: self.disposeBag)
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
}

extension DMSpotifySongSearchViewController {
    
    static func persistedSongDataSource(withViewModel viewModel: DMSpotifySongSearchViewModelType) -> RxTableViewSectionedAnimatedDataSource<SongSection> {
        
        return RxTableViewSectionedAnimatedDataSource<SongSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .top, reloadAnimation: .fade, deleteAnimation: .left),
            configureCell: { (dataSource, tableView, indexPath, element) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: DMSpotifySongTableViewCell.reuseIdentifier, for: indexPath)
                
                guard let songCell = cell as? DMSpotifySongTableViewCell else {
                    return cell
                }
                
                songCell.configure(
                    withSong: element
                )
                
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
            }
        )
    }
    
}
