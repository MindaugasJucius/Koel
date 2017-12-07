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
    
    private var backgroundTaskID = UIBackgroundTaskInvalid
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        
        let sceneCoordinator = SceneCoordinator(window: window!)
        
        let flowSelectionViewModel = DMFlowSelectionViewModel(withSceneCoordinator: sceneCoordinator)
        let flowSelectionScene = Scene.selectFlow(flowSelectionViewModel)
        
        sceneCoordinator.transition(to: flowSelectionScene, type: .root)

        return true
    }
    
    // participant
    
    // enter background
    // disconnect from session
    
    // enter foreground
    // retrieve host if available
        // try to connect ->
            // success: show event management
            // failure: show flow selection
    
    // host
    
    // persist on retrieving songs
    
    // enter background
    // extend multipeer lifecycle with background tasks (about 180s)
    // disconnect on task expiration
    
    // enter foreground
    // wait for reconnections from participants
        // try to connect to each one of them ->
            // send song list
            // send currently playing song id
    
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

}

