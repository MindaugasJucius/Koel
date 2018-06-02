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
    
    static func persistedSongDataSource(withViewModel viewModel: DMEventParticipantSongsEditable) -> RxTableViewSectionedReloadDataSource<SongSection> {
        return RxTableViewSectionedReloadDataSource<SongSection>(
            configureCell: { (dataSource, tableView, indexPath, element) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: DMEventSongPersistedTableViewCell.reuseIdentifier, for: indexPath)
                
                guard let songCell = cell as? DMEventSongPersistedTableViewCell else {
                    return cell
                }

                songCell.configure(
                    withSong: element,
                    upvoteAction: viewModel.onUpvote(element)
                )
                
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
            }
        )
    }
    
}
