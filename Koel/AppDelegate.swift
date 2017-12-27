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
    private weak var spotifyService: DMSpotifyService? = nil
    
    private var backgroundTaskID = UIBackgroundTaskInvalid
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        
        let sceneCoordinator = SceneCoordinator(window: window!)
        let spotifyService = DMSpotifyService(withSceneCoordinator: sceneCoordinator)
        
        let flowSelectionViewModel = DMFlowSelectionViewModel(withSceneCoordinator: sceneCoordinator, spotifyService: spotifyService)
        let flowSelectionScene = Scene.selectFlow(flowSelectionViewModel)
        
        sceneCoordinator.transition(to: flowSelectionScene, type: .root)
        
        self.spotifyService = spotifyService
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
        guard let spotifyService = spotifyService else {
            return false
        }
        
        spotifyService.handle(callbackURL: url)
        return true
    }

}

