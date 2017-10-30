//
//  AppCoordinator.swift
//  Koel
//
//  Created by Mindaugas Jucius on 27/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import CloudKit

class AppCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController?

    var childCoordinators: [Coordinator] = []
    
    required init(withNavigationController navigationController: UINavigationController?) {
        self.navigationController = navigationController
        super.init()
        performInitialConfiguration()
    }
    
    func start() {
        if DMUserDefaultsHelper.CloudKitUserRecord == nil {
            let initialCoordinator = initialLoadingCoordinator()
            initialCoordinator.start()
        } else {
            adjustToEventExistence()
        }
    }
    
    private func performInitialConfiguration() {
        navigationController?.isNavigationBarHidden = true
    }
    
    private func adjustToEventExistence() {
        if let currentEvent = DMUserDefaultsHelper.CurrentEventRecord {
            showSongQueue(withCurrentEvent: currentEvent)
        } else {
            showEventCreation()
        }
    }
    
    private func showSongQueue(withCurrentEvent eventRecord: CKRecord) {
        let event = DMEvent.from(CKRecord: eventRecord)
        let queueVC = DMSongQueueViewController(withEvent: event)
        navigationController?.pushViewController(queueVC, animated: false)
    }
    
    private func showEventCreation() {
        let eventVC = DMEventCreationViewController()
        navigationController?.pushViewController(eventVC, animated: false)
    }
    
    // MARK: - Child Coordinator Creation
    
    private func initialLoadingCoordinator() -> DMInitialLoadingCoordinator {
        let coordinator = DMInitialLoadingCoordinator(withNavigationController: navigationController)
        coordinator.delegate = self
        childCoordinators.append(coordinator)
        return coordinator
    }
    
}

extension AppCoordinator: DMInitialLoadingCoordinatorDelegate {
    
    func initialLoadingSucceeded(withUser user: DMUser) {
        // Show Song Queue controller if an event exists (means it has been joined, if it's stored to User Defaults).
        // Otherwise adjusts app's flow from Event creation/joining controller
        adjustToEventExistence()
    }
    
    func initialLoadingFailed(withError error: Error) {
        
    }
    
}
