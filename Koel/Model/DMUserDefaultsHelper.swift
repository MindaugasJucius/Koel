//
//  DMUserDefaultsHelper.swift
//  Koel
//
//  Created by Mindaugas Jucius on 13/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation

class DMUserDefaultsHelper: NSObject {

    static let iCloudUserIDKey = "iCloudUserID"
    
    static func set(value: Any, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static var iCloudUserID: String? {
        return UserDefaults.standard.string(forKey: iCloudUserIDKey)
    }
    
}
