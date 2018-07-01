//
//  DMSearchResultSong.swift
//  Koel
//
//  Created by Mindaugas on 25/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Spartan
import ObjectMapper

struct DMSearchResultSong {
    
    let title: String
    let artistName: String
    let albumName: String
    let spotifyURI: String
    let durationSeconds: TimeInterval
    let albumArtworkImageURL: URL?
    var image: UIImage?
}

extension DMSearchResultSong {
    
    static func create(from paginatableMappable: Paginatable & Mappable) -> DMSearchResultSong? {
        if let savedTrack = paginatableMappable as? SavedTrack {
            return DMSearchResultSong.createSavedTrackRepresentable(from: savedTrack)
        }
        return nil
    }
    
    private static func createSavedTrackRepresentable(from savedTrack: SavedTrack) -> DMSearchResultSong {
        let artistName = savedTrack.track.album.artists.reduce("", { currentTitle, artist in
            return currentTitle.appending("\(artist.name!) ")
        })
        
        var albumArtworkImageURL: URL? = nil
        
        if let smallestImageURL = savedTrack.track.album.images.last?.url {
            albumArtworkImageURL = URL(string: smallestImageURL)
        }

        return DMSearchResultSong(title: savedTrack.track.name,
                                  artistName: artistName,
                                  albumName: savedTrack.track.album.name,
                                  spotifyURI: savedTrack.track.uri,
                                  durationSeconds: TimeInterval(savedTrack.track.durationMs) / 1000,
                                  albumArtworkImageURL: albumArtworkImageURL,
                                  image: nil)

    }
    
}

extension DMSearchResultSong: Equatable {

    static func == (lhs: DMSearchResultSong, rhs: DMSearchResultSong) -> Bool {
        return lhs.spotifyURI == rhs.spotifyURI
    }
    
}

