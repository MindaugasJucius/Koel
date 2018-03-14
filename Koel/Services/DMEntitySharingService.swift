//
//  DMEventSongSharingService.swift
//  Koel
//
//  Created by Mindaugas Jucius on 20/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift

struct DMEntitySharingService<T: Codable>: DMEntitySharingServiceType {
    
    typealias Entity = T
    
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
    
    func encode(entity: T) throws -> Data {
        return try encoder.encode(entity)
    }
    
    func parse(fromData data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
    
}
