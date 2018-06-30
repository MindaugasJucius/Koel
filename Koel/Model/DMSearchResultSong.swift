//
//  DMSearchResultSong.swift
//  Koel
//
//  Created by Mindaugas on 25/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Spartan

struct DMSearchResultSong {
    
    let title: String
    let artistName: String
    let albumName: String
    let spotifyURI: String
    let durationSeconds: TimeInterval
    let albumArtworkImageURL: String
    
}

extension DMSearchResultSong {
    
    static func create(from savedTrack: SavedTrack) -> DMSearchResultSong {
        let artistName = savedTrack.track.album.artists.reduce("", { currentTitle, artist in
            return currentTitle.appending("\(artist.name!) ")
        })
        return DMSearchResultSong(title: savedTrack.track.name,
                                  artistName: artistName,
                                  albumName: savedTrack.track.album.name,
                                  spotifyURI: savedTrack.track.uri,
                                  durationSeconds: TimeInterval(savedTrack.track.durationMs) / 1000,
                                  albumArtworkImageURL: savedTrack.track.album.images[0].url)

    }
    
}

extension DMSearchResultSong: Equatable {

    static func == (lhs: DMSearchResultSong, rhs: DMSearchResultSong) -> Bool {
        return lhs.spotifyURI == rhs.spotifyURI
    }
    
}

