//
//  DMEventSongSharingServiceType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 20/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift

protocol DMEventSongSharingServiceType {
    
    func encode(song: DMEventSong) throws -> Data
    func parseSong(fromData: Data) throws -> DMEventSong
}
