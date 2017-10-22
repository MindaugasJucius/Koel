//
//  CKRecordExtension.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/14/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import CloudKit

extension CKRecord {
    
    subscript<T: RawRepresentable>(modelEnum: T) -> Any? where T.RawValue == String {
        get {
            return self[modelEnum.rawValue]
        }
        set {
            self[modelEnum.rawValue] = newValue as? CKRecordValue
        }
    }
    
}
