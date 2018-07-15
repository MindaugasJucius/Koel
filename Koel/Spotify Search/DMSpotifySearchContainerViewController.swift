//
//  DMSpotifySearchContainerViewController.swift
//  Koel
//
//  Created by Mindaugas on 15/07/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit

private enum SpotifySearchScopes: String {
    case tracks
    case albums
    case playlists
}

class DMSpotifySearchContainerViewController: UISearchContainerViewController {

    private let searchScopes: [SpotifySearchScopes] = [.tracks, .albums, .playlists]
    
    private var addSongsButton: DMKoelButton

    init() {
        self.addSongsButton = DMKoelButton(themeManager: ThemeManager.shared)
        super.init(searchController: UISearchController(searchResultsController: nil))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = UIConstants.strings.searchSongs
        searchController.searchBar.scopeButtonTitles = searchScopes.map { $0.rawValue }
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
    }

}

extension DMSpotifySearchContainerViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print(searchScopes[selectedScope])
    }
    
}

