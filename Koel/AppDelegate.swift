//
//  AppDelegate.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/12/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    //var spotifyAuthService: DMSpotifyAuthService? = nil
    
    private var backgroundTaskID = UIBackgroundTaskInvalid
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        
        let sceneCoordinator = SceneCoordinator(window: window!)
        
        let eventSearchViewModel = DMEventSearchViewModel(withSceneCoordinator: sceneCoordinator)
        let eventSearchScene = Scene.search(eventSearchViewModel)

        sceneCoordinator.transition(to: eventSearchScene, type: .rootWithNavigationVC)
        
        //self.spotifyAuthService = DMSpotifyAuthService(sceneCoordinator: sceneCoordinator)
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notifications.willEnterForeground, object: nil)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("will resign active")
        NotificationCenter.default.post(name: Notifications.willResignActive, object: nil)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("did enter background")
        NotificationCenter.default.post(name: Notifications.didEnterBackground, object: nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notifications.didBecomeActive, object: nil)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("application will terminate")
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        //spotifyAuthService?.handle(callbackURL: url)
        guard SPTAuth.defaultInstance().canHandle(url) else {
            return false
        }
        NotificationCenter.default.post(
            name: SpotifyURLCallbackNotification,
            object: nil,
            userInfo: [SpotifyURLCallbackNotificationUserInfoURLKey : url]
        )
        return true
    }

}

