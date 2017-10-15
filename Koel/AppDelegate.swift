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

let SongsNotification = Notification(name: SongsUpdateNotificationName)
let SongsUpdateNotificationName = Notification.Name("songs updated notification")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    private let eventManager = DMEventManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("D'oh: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        
        if DMUserDefaultsHelper.CurrentEventRecord != nil {
            eventManager.saveSongCreationSubscription()
        }
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
 
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        if notification.subscriptionID == DMEventManager.SongCreationSubscriptionID && notification.notificationType == .query {
            NotificationCenter.default.post(SongsNotification)
            let queryNotification = notification as? CKQueryNotification
            
            completionHandler(UIBackgroundFetchResult.newData)
        }
        completionHandler(UIBackgroundFetchResult.noData)
    }

}

