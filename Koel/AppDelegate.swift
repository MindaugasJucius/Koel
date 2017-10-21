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

    private let userManager = DMUserManager()
    
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        application.registerForRemoteNotifications()
        
        window?.makeKeyAndVisible()

        let updateRootViewController = {
            let rootViewController: UIViewController
            // Show Queue controller if an event exists (means it has been joined, if it's stored to User Defaults).
            // Otherwise begin app's flow from Event creation/joining controller
            if let currentEvent = DMUserDefaultsHelper.CurrentEventRecord {
                rootViewController = DMSongQueueViewController(withEvent: DMEvent.from(CKRecord: currentEvent))
            } else {
                rootViewController = DMEventCreationViewController()
            }
            self.window?.rootViewController = rootViewController
        }
        
        // If current User hasn't been determined yet, fetch full record
        guard DMUserDefaultsHelper.CloudKitUserRecord == nil else {
            updateRootViewController()
            return true
        }
        
        self.window?.rootViewController = DMInitialLoadingViewController()
        
        let initialSetupGroup = DispatchGroup()
        
        initialSetupGroup.enter()
        
        userManager.fetchFullCurrentUserRecord(
            success: { user in
                initialSetupGroup.leave()
            },
            failure: { error in
                initialSetupGroup.leave()
            }
        )
    
        // Update app's rootViewController after fetching User's record
        initialSetupGroup.notify(queue: DispatchQueue.main) {
            updateRootViewController()
        }

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

