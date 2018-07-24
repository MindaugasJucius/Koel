//
//  DMSpotifySearchContainerViewController.swift
//  Koel
//
//  Created by Mindaugas on 15/07/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift
import Spartan

private enum SpotifySearchScopes: String {
    case tracks
    case albums
    case playlists
}

extension SpotifySearchScopes {
    
    var localized: String {
        switch self {
        case .albums:
            return UIConstants.strings.albums
        case .tracks:
            return UIConstants.strings.tracks
        case .playlists:
            return UIConstants.strings.playlists
        }
    }
    
    var itemSearchType: ItemSearchType {
        switch self {
        case .albums:
            return ItemSearchType.album
        case .playlists:
            return ItemSearchType.playlist
        case .tracks:
            return ItemSearchType.track
        }
    }
    
}

class DMSpotifySearchContainerViewController: UISearchContainerViewController, BindableType {

    typealias ViewModelType = DMSpotifySearchContainerViewModelType

    private let searchScopes: [SpotifySearchScopes] = [.tracks, .albums, .playlists]
    private let disposeBag = DisposeBag()
    
    var viewModel: DMSpotifySearchContainerViewModelType
    private var addSongsButton: DMKoelButton
    
    private lazy var tracksViewController: DMSpotifyTracksViewController<DMSearchResultSong> = {
        let spotifyTracksViewController = DMSpotifyTracksViewController<DMSearchResultSong>(withViewModel: viewModel.tracksViewModel,
                                                                                            themeManager: ThemeManager.shared)
        spotifyTracksViewController.setupForViewModel()
        return spotifyTracksViewController
    }()

    init(viewModel: DMSpotifySearchContainerViewModelType) {
        self.viewModel = viewModel
        self.addSongsButton = DMKoelButton(themeManager: ThemeManager.shared)
        super.init(searchController: UISearchController(searchResultsController: nil))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = UIConstants.strings.searchSongs
        searchController.searchBar.scopeButtonTitles = searchScopes.map { $0.localized }

        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false

        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        guard let navigationControllerView = navigationController?.view else {
            return
        }
        navigationControllerView.addSubview(addSongsButton)
        addSongsButton.setTitle(UIConstants.strings.addSelectedSongs, for: .normal)
        addSongsButton.addConstraints(inSuperview: navigationControllerView)
    
        addChildViewController(tracksViewController)
        view.addSubview(tracksViewController.view)
        tracksViewController.didMove(toParentViewController: self)
    }

    func bindViewModel() {
        addSongsButton.rx.action = viewModel.queueSelectedSongs
        
        viewModel.queueSelectedSongs.executing
            .filter { $0 }
            .debounce(0.3, scheduler: MainScheduler.instance)
            .do(onNext: { _ in
//                self.tableView.indexPathsForSelectedRows?.forEach {
//                    self.tableView.deselectRow(at: $0, animated: false)
//                }
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        bindSearchBar()
    }
    
    private func bindSearchBar() {
        let selectedSearchType = searchController.searchBar.rx.selectedScopeButtonIndex
            .map { self.searchScopes[$0].itemSearchType }
        
        let searchBarText = searchController.searchBar.rx.text
            .filterNil()
            .debounce(0.5, scheduler: MainScheduler.instance)
        
//        Observable.combineLatest(searchBarText, selectedSearchType)
//            .skip(1)
//            .map { self.viewModel.searchViewModel(withQuery: $0, itemType: $1) }
//            .map { searchViewModel -> UIViewController in
//                let searchResultsViewController = DMSpotifyTracksViewController(withViewModel: searchViewModel,
//                                                                                themeManager: ThemeManager.shared)
//                searchResultsViewController.setupForViewModel()
//                return searchResultsViewController
//            }
//            .do(onNext: { [unowned self] viewController in
//                self.addChildViewController(viewController)
//                self.view.addSubview(viewController.view)
//                viewController.didMove(toParentViewController: self)
//            })
//            .subscribe()
//            .disposed(by: disposeBag)
        
    }
    
}

extension DMSpotifySearchContainerViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print(searchScopes[selectedScope])
    }
    
}


