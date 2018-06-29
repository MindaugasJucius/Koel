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
import Action

class DMEventManagementViewController: UIViewController, BindableType {
    
    typealias ViewModelType = DMEventManagementViewModelType

    private let disposeBag = DisposeBag()
    
    var viewModel: DMEventManagementViewModelType
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(DMEventSongPersistedTableViewCell.self, forCellReuseIdentifier: DMEventSongPersistedTableViewCell.reuseIdentifier)
        return tableView
    }()
    
    private lazy var deleteSongsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(UIConstants.strings.deleteSongs, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        return button
    }()
    
    private let playbackControlsView = DMPlaybackControlsView(frame: .zero)
    
    required init(withViewModel viewModel: DMEventManagementViewModelType) {
        self.viewModel = viewModel
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
        navigationItem.largeTitleDisplayMode = .always
        title = UIConstants.strings.managementTitle
        view.backgroundColor = .white
        view.addSubview(tableView)
        
        let tableViewConstraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        
        view.addSubview(playbackControlsView)
        let playbackControlsViewConstraints = [
            playbackControlsView.heightAnchor.constraint(equalToConstant: DMPlaybackControlsView.height),
            playbackControlsView.leftAnchor.constraint(equalTo: view.leftAnchor),
            playbackControlsView.rightAnchor.constraint(equalTo: view.rightAnchor),
            playbackControlsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]


        NSLayoutConstraint.activate(playbackControlsViewConstraints)
        NSLayoutConstraint.activate(tableViewConstraints)
        
        #if DEBUG
            view.addSubview(deleteSongsButton)
            let deleteSongsButtonConstraints = [
                deleteSongsButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor,
                                                         constant: -20),
                deleteSongsButton.bottomAnchor.constraint(equalTo: playbackControlsView.topAnchor)
            ]
        
            NSLayoutConstraint.activate(deleteSongsButtonConstraints)
        #endif
    }
    
    func bindViewModel() {

        let songsDataSource = DMEventManagementViewController.persistedSongDataSource(withViewModel: viewModel)
        
        viewModel.songsSectioned
            .bind(to: tableView.rx.items(dataSource: songsDataSource))
            .disposed(by: disposeBag)
        
        deleteSongsButton.rx.action = viewModel.onSongsDelete
        
        //DMPlaybackControlsView bindings
        self.viewModel.playbackEnabled
            .bind(to: playbackControlsView.playPauseSongButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        playbackControlsView.nextSongButton.rx.action = viewModel.onNext
        playbackControlsView.playPauseSongButton.rx.action = viewModel.onPlay
        
        viewModel.isPlaying.map { $0 ? "PAUSE" : "PLAY" }
            .bind(to: playbackControlsView.playPauseSongButton.rx.title())
            .disposed(by: disposeBag)
    }
    
}
