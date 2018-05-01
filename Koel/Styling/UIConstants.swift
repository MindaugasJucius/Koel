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

        static let koelPink = UIColor(red: 235/255, green: 2/255, blue: 141/255, alpha: 1)
        static let koelBlue = UIColor.colorWithHexString(hex: "#19B5FE")
        static let koelSkyBlue = UIColor.colorWithHexString(hex: "#EC6EAD")
        static let koelPurple = UIColor.colorWithHexString(hex: "#3494E6")
        
        struct logoView {
            static let firstScaleLayerColor = koelBlue.withAlphaComponent(0.4).cgColor
            static let secondScaleLayerColor = koelBlue.withAlphaComponent(0.6).cgColor
            
            static let gradientStartColor = UIColor.colorWithHexString(hex: "#00dbde").cgColor
            static let gradientEndColor = UIColor.colorWithHexString(hex: "#fc00ff").cgColor
        }
    }
    
    struct strings {
        
        // General
        static let done = NSLocalizedString("DONE", comment: "")
        static let queuedSongs = NSLocalizedString("QUEUED_SONGS_SECTION_TITLE", comment: "")
        static let playedSongs = NSLocalizedString("PLAYED_SONGS_SECTION_TITLE", comment: "")
        
        // Management
        static let addSong = NSLocalizedString("ADD_SONG", comment: "")
        static let deleteSongs = NSLocalizedString("DELETE_SONGS", comment: "")
        static let invite = NSLocalizedString("INVITE", comment: "")
        static let managementTitle = NSLocalizedString("MANAGEMENT_TITLE", comment: "")
        static let nearbyPeers = NSLocalizedString("NEARBY_PEERS_SECTION_TITLE", comment: "")
        static let joinedPeers = NSLocalizedString("JOINED_PEERS_SECTION_TITLE", comment: "")
        
        // Participate
        static let participateTitle = NSLocalizedString("PARTICIPATE_TITLE", comment: "")
        
        // Search
        static let searchScreenTitle = NSLocalizedString("SEARCH_SCREEN_TITLE", comment: "")
        static let searchScreenButtonStartEventTitle = NSLocalizedString("SEARCH_SCREEN_TITLE_START", comment: "")
    }
    
}
