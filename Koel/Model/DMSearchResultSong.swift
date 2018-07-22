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

protocol ImageContaining {
    var imageURL: URL? { get }
    var image: UIImage? { get set }
}

protocol Representing: Equatable {
    static func create(from paginatableMappable: Paginatable & Mappable) -> Self?
}

struct DMSearchResultSong: Representing, ImageContaining {
    
    let title: String
    let artistName: String
    let albumName: String
    let spotifyURI: String
    let durationSeconds: TimeInterval
    let imageURL: URL?
    var image: UIImage?
    
    static func ==(lhs: DMSearchResultSong, rhs: DMSearchResultSong) -> Bool {
        return lhs.image == rhs.image
    }

}

extension DMSearchResultSong {
    
    static func create(from paginatableMappable: Paginatable & Mappable) -> DMSearchResultSong? {
        if let savedTrack = paginatableMappable as? SavedTrack {
            return DMSearchResultSong.createTrackRepresentable(from: savedTrack.track)
        }
        if let track = paginatableMappable as? Track {
            return DMSearchResultSong.createTrackRepresentable(from: track)
        }
        return nil
    }
    
    private static func createTrackRepresentable(from track: Track) -> DMSearchResultSong {
        let artistName = track.album.artists.reduce("", { currentTitle, artist in
            return currentTitle.appending("\(artist.name!) ")
        })
        
        var albumArtworkImageURL: URL? = nil
        
        if let smallestImageURL = track.album.images.last?.url {
            albumArtworkImageURL = URL(string: smallestImageURL)
        }
        
        return DMSearchResultSong(title: track.name,
                                  artistName: artistName,
                                  albumName: track.album.name,
                                  spotifyURI: track.uri,
                                  durationSeconds: TimeInterval(track.durationMs) / 1000,
                                  imageURL: albumArtworkImageURL,
                                  image: nil)
    }
    
}
