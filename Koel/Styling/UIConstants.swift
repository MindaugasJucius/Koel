//
//  UIConstants.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

struct UIConstants {
    
    struct colors {
        struct logoView {
            static let firstScaleLayerColor = UIColor.white.cgColor
            static let secondScaleLayerColor = UIColor.white.cgColor
            
            static let gradientStartColor = UIColor.colorWithHexString(hex: "#00dbde").cgColor
            static let gradientEndColor = UIColor.colorWithHexString(hex: "#fc00ff").cgColor
        }
    }
    
    struct strings {
        
        // General
        static let done = NSLocalizedString("DONE", comment: "")
        static let queuedSongs = NSLocalizedString("QUEUED_SONGS_SECTION_TITLE", comment: "")
        static let playedSongs = NSLocalizedString("PLAYED_SONGS_SECTION_TITLE", comment: "")
        static let later = NSLocalizedString("LATER", comment: "")
        static let authenticate = NSLocalizedString("AUTHENTICATE", comment: "")
        static let noSearchResults = NSLocalizedString("NO_SEARCH_RESULTS", comment: "")

        // Song Search
        static let addSelectedSongs = NSLocalizedString("ADD_SELECTED_SONGS", comment: "")
        static let searchSongs = NSLocalizedString("SEARCH_SPOTIFY", comment: "")

        // SPT Actions
        static let SPTActionPlayback = NSLocalizedString("SPT_ACTION_PLAYBACK", comment: "")
        static let SPTSearchTracks = NSLocalizedString("SPT_ACTION_SEARCH_TRACKS", comment: "")
        
        // SPT General
        static let pleaseLoginToPerformAction = NSLocalizedString("PLEASE_LOGIN_TO_PERFORM_ACTION", comment: "")
        static let enterToSearch = NSLocalizedString("ENTER_TO_SEARCH", comment: "")
        static let userSavedTracks = NSLocalizedString("USER_SAVED_TRACKS", comment: "")
        
        // SPT Errors
        static let loginToPerformActionError = NSLocalizedString("NEED_TO_LOGIN_TO_PERFORM_ACTION_ERROR", comment: "")

        // Management
        static let deleteSongs = NSLocalizedString("DELETE_SONGS", comment: "")
        static let invite = NSLocalizedString("INVITE", comment: "")
        static let managementTitle = NSLocalizedString("MANAGEMENT_TITLE", comment: "")
        static let nearbyPeers = NSLocalizedString("NEARBY_PEERS_SECTION_TITLE", comment: "")
        static let joinedPeers = NSLocalizedString("JOINED_PEERS_SECTION_TITLE", comment: "")
        static let refreshCache = NSLocalizedString("REFRESH_SONG_CACHE", comment: "")
        
        // Participate
        static let participateTitle = NSLocalizedString("PARTICIPATE_TITLE", comment: "")
        
        // Event Search
        static let searchScreenTitle = NSLocalizedString("SEARCH_SCREEN_TITLE", comment: "")
        static let searchScreenButtonStartEventTitle = NSLocalizedString("SEARCH_SCREEN_TITLE_START", comment: "")
    }
    
}
