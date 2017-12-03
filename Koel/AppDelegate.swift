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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window?.makeKeyAndVisible()
        let navigationControllerScene = Scene.rootNavigation
        window?.rootViewController = navigationControllerScene.viewController()
        
        let sceneCoordinator = SceneCoordinator(window: window!)

        let flowSelectionViewModel = DMFlowSelectionViewModel(withSceneCoordinator: sceneCoordinator)
        let flowSelectionCreationScene = Scene.selectFlow(flowSelectionViewModel)

        sceneCoordinator.transition(to: flowSelectionCreationScene, type: .push)
        
        return true
    }

}

