//
//  DMEventSongSharingServiceType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 20/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation

protocol DMEntitySharingServiceType {
    
    associatedtype Entity
    
    func encode(entity: Entity) throws -> Data
    func parse(fromData data: Data) throws -> Entity
    
}
