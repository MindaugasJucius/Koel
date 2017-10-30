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
    private var appCoordinator: AppCoordinator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        application.registerForRemoteNotifications()
        
        let navigationController = UINavigationController()
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        appCoordinator = AppCoordinator(withNavigationController: navigationController)
        appCoordinator?.start()
        
        return true
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
            guard let queryNotification = notification as? CKQueryNotification,
            let queryNotificationSongID = queryNotification.recordID else {
                return
            }
            let songIDDict = [
                DMSong.notificationSongIDKey: queryNotificationSongID,
                DMSong.notificationReasonSongKey: queryNotification.queryNotificationReason
                ] as [String : Any]
            NotificationCenter.default.post(name: SongsNotification.name, object: nil, userInfo: songIDDict)
            completionHandler(UIBackgroundFetchResult.newData)
        }
        completionHandler(UIBackgroundFetchResult.noData)
    }

}

