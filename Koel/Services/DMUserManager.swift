//
//  DMUserManager.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/14/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

class DMUserManager: NSObject, DMManager {

    func fetchCloudKitCurrentUserId(success: ((String) -> ())? = nil, failure: ((Error) -> ())? = nil) {
        if let userId = DMUserDefaultsHelper.CloudKitUserID {
            success?(userId)
            return
        }
        cloudKitContainer.fetchUserRecordID { recordId, error in
            if let error = error {
                failure?(error)
                print(error.localizedDescription)
            } else if let userIdRecord = recordId {
                let userId = userIdRecord.recordName
                DMUserDefaultsHelper.set(value: userId, forKey: DMUserDefaultsHelper.CloudKitUserIDKey)
                success?(userId)
            }
        }
    }
    
}
