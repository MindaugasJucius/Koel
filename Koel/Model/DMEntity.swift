//
//  DMEntity.swift
//  Koel
//
//  Created by Mindaugas on 07/04/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation

protocol DMEntity {
    
    var uuid: String { get set }
    var primaryKeyRef: String { get set }
    
}
