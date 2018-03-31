//
//  Bindable+SongTableView.swift
//  Koel
//
//  Created by Mindaugas on 24/03/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxDataSources

extension BindableType {
    
    static func dataSource(withViewModel viewModel: SongSharingViewModelType) -> RxTableViewSectionedAnimatedDataSource<SongSection> {
        return RxTableViewSectionedAnimatedDataSource<SongSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .top, reloadAnimation: .fade, deleteAnimation: .left),
            configureCell: { (dataSource, tableView, indexPath, element) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: DMEventSongPersistedTableViewCell.reuseIdentifier, for: indexPath)
                
                guard let songCell = cell as? DMEventSongPersistedTableViewCell else {
                    return cell
                }
                
                songCell.configure(
                    withSong: element,
                    upvoteAction: viewModel.songSharingViewModel.onUpvote(song: element)
                )
                
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
            }
        )
    }
    
}
