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
    
    typealias ViewModelType = DMEventManagementViewModel

    private let disposeBag = DisposeBag()
    
    var viewModel: DMEventManagementViewModel
    
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
    
    private let playbackControlsView = DMPlaybackControlsView(frame: .zero)
    
    required init(withViewModel viewModel: DMEventManagementViewModel) {
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
            invitationsButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20),
            invitationsButton.bottomAnchor.constraint(equalTo: playbackControlsView.topAnchor)
        ]
        
        view.addSubview(addButton)
        
        let addButtonConstraints = [
            addButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: playbackControlsView.topAnchor)
        ]
        

        NSLayoutConstraint.activate(playbackControlsViewConstraints)
        NSLayoutConstraint.activate(invitationConstraints)
        NSLayoutConstraint.activate(addButtonConstraints)
        NSLayoutConstraint.activate(tableViewConstraints)
    }
    
    func bindViewModel() {
        let dataSource = DMEventManagementViewController.persistedSongDataSource(withViewModel: viewModel)
        
        viewModel.songSharingViewModel.songsSectioned
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelSelected(DMEventSong.self)
            .filter { $0.played == .none }
            .subscribe(viewModel.songSharingViewModel.onPlayed.inputs)
            .disposed(by: disposeBag)

        addButton.rx.action = viewModel.songSharingViewModel.onSongSearch
        invitationsButton.rx.action = viewModel.onInvite()
        
        //DMPlaybackControlsView bindings

        let queuedSongsAvailable = viewModel.songSharingViewModel.queuedSongs.map { songs in
            return !songs.isEmpty
        }.share()
            
        queuedSongsAvailable
            .bind(to: playbackControlsView.playPauseSongButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        queuedSongsAvailable
            .bind(to: playbackControlsView.previousSongButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        playbackControlsView.nextSongButton.rx.action = viewModel.onNext
        playbackControlsView.playPauseSongButton.rx.action = viewModel.onPlay
        playbackControlsView.previousSongButton.rx.action = viewModel.onPrevious
    }
    
}
