//
//  AppDelegate.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/12/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications

let SongsUpdateNotificationName = Notification.Name("Songs-Updated-Notification")
let SongsNotification = Notification(name: SongsUpdateNotificationName)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let navigationController = UINavigationController()
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        let sceneCoordinator = SceneCoordinator(window: window!)
        
        let eventCreationViewModel = DMEventCreationViewModel(withSceneCoordinator: sceneCoordinator)
        let eventCreationScene = Scene.create(eventCreationViewModel)
        sceneCoordinator.transition(to: eventCreationScene, type: .root)
        
        return true
    }

}

