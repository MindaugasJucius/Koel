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
    
    private lazy var invitationsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(UIConstants.strings.invite, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        return button
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(UIConstants.strings.addSong, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        return button
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
        navigationController?.navigationBar.apply(DefaultStylesheet.navigationBarStyle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = UIConstants.strings.managementTitle
        view.backgroundColor = .white
        view.addSubview(tableView)
        
        let tableViewConstraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        view.addSubview(invitationsButton)

        
        view.addSubview(playbackControlsView)
        let playbackControlsViewConstraints = [
            playbackControlsView.heightAnchor.constraint(equalToConstant: DMPlaybackControlsView.height),
            playbackControlsView.leftAnchor.constraint(equalTo: view.leftAnchor),
            playbackControlsView.rightAnchor.constraint(equalTo: view.rightAnchor),
            playbackControlsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        let invitationConstraints = [
            invitationsButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor,
                                                    constant: 20),
            invitationsButton.bottomAnchor.constraint(equalTo: playbackControlsView.topAnchor)
        ]
        
        view.addSubview(addButton)
        
        let addButtonConstraints = [
            addButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor,
                                             constant: -20),
            addButton.bottomAnchor.constraint(equalTo: playbackControlsView.topAnchor)
        ]

        NSLayoutConstraint.activate(playbackControlsViewConstraints)
        NSLayoutConstraint.activate(invitationConstraints)
        NSLayoutConstraint.activate(addButtonConstraints)
        NSLayoutConstraint.activate(tableViewConstraints)
        
        
        #if DEBUG
            view.addSubview(deleteSongsButton)
            let deleteSongsButtonConstraints = [
                deleteSongsButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor,
                                                         constant: -20),
                deleteSongsButton.bottomAnchor.constraint(equalTo: addButton.topAnchor)
            ]
        
            NSLayoutConstraint.activate(deleteSongsButtonConstraints)
        #endif
    }
    
    func bindViewModel() {

        let songsDataSource = DMEventManagementViewController.persistedSongDataSource(withViewModel: viewModel)
        
        viewModel.songsSectioned
            .bind(to: tableView.rx.items(dataSource: songsDataSource))
            .disposed(by: disposeBag)
        
        addButton.rx.action = viewModel.onSongSearch
        deleteSongsButton.rx.action = viewModel.onSongsDelete
        invitationsButton.rx.action = viewModel.onInvite
        
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
