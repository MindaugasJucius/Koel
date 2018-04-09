//
//  Array+Extensions.swift
//  Koel
//
//  Created by Mindaugas on 08/04/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation

extension Collection {
    
    // Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
