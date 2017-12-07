//
//  Notifications.swift
//  Koel
//
//  Created by Mindaugas Jucius on 05/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation

struct Notifications {
    
    static let didBecomeActive = Notification.Name("didBecomeActive")
    static let willResignActive = Notification.Name("willResignActive")
    static let didEnterBackground = Notification.Name("didEnterBackground")
    static let willEnterForeground = Notification.Name("willEnterForeground")
}
