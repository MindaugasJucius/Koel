//
//  DisconnectOnExpirationType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 07/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import UIKit

protocol BackgroundDisconnectType: class, MultipeerViewModelType {
    
    var backgroundTaskID: UIBackgroundTaskIdentifier { get set }
    
}

extension BackgroundDisconnectType {
    
    var didEnterBackgroundNotificationHandler: (Notification) -> () {
        return { [unowned self] (notification: Notification) in
            guard notification.name == Notifications.didEnterBackground else {
                return
            }
            
            self.backgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                    self.multipeerService.disconnect()
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                    self.backgroundTaskID = UIBackgroundTaskInvalid
                    print("background task expired")
                }
            )
        }
    }
    
    var willEnterForegroundNotificationHandler: (Notification) -> () {
        return { [unowned self] (notification: Notification) in
            guard notification.name == Notifications.willEnterForeground else {
                return
            }
            if self.backgroundTaskID != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                self.backgroundTaskID = UIBackgroundTaskInvalid
            }
        }
    }
    
}
