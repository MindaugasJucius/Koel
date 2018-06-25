//
//  DMSearchResultSong.swift
//  Koel
//
//  Created by Mindaugas on 25/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation

struct DMSearchResultSong {
    let title: String
    let artistName: String
    let spotifyURI: String
    let durationMilliseconds: Int
    let albumArtworkImageURL: String
    
    
}

extension DMSearchResultSong: Equatable {

    static func == (lhs: DMSearchResultSong, rhs: DMSearchResultSong) -> Bool {
        return true
    }
    
}

