//
//  DMEventSongSharingService.swift
//  Koel
//
//  Created by Mindaugas Jucius on 20/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift

struct DMEventSongSharingService: DMEventSongSharingServiceType {
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    func encode(song: DMEventSong) throws -> Data {
        return try encoder.encode(song)
    }
    
    func parseSong(fromData data: Data) throws -> DMEventSong {
        return try decoder.decode(DMEventSong.self, from: data)
    }
}
