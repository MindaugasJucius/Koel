//
//  EventManagementSceneCoordinator.swift
//  Koel
//
//  Created by Mindaugas on 23/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift

protocol RootTransitioning {
    func beginCoordinating(withWindow window: UIWindow)
}

private enum ManagementScene {
    case invites
    case songs
    case search
}

class DMEventManagementSceneCoordinator: NSObject, RootTransitioning {

    private var currentViewController: UIViewController?
    private let reachabilityService = try! DefaultReachabilityService()
    private let multipeerService = DMEventMultipeerService(asEventHost: true)
    
    private let pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                          navigationOrientation: .horizontal,
                                                          options: nil)
    
    private let scenes: [ManagementScene] = [.invites, .songs, .search]
    
    private lazy var songsViewController: UINavigationController = {
        let songPersistenceService = DMEventSongPersistenceService(selfPeer: multipeerService.myEventPeer)
        let songSharingViewModel = DMEventSongSharingViewModel(songPersistenceService: songPersistenceService,
                                                               reachabilityService: self.reachabilityService,
                                                               songSharingService: DMEntitySharingService(),
                                                               multipeerService: multipeerService)
        
        let manageEventViewModel = DMEventManagementViewModel(multipeerService: multipeerService,
                                                              reachabilityService: self.reachabilityService,
                                                              promptCoordinator: self,
                                                              songsRepresenter: songSharingViewModel,
                                                              songsEditor: songSharingViewModel)
        let managementVC = DMEventManagementViewController(withViewModel: manageEventViewModel)
        managementVC.setupForViewModel()
        return UINavigationController(rootViewController: managementVC)
    }()
    
    private lazy var invitesViewController: UINavigationController = {
        let invitationsViewModel = DMEventInvitationsViewModel(multipeerService: multipeerService)
        
        let invitationsVC = DMEventInvitationsViewController(withViewModel: invitationsViewModel)
        invitationsVC.setupForViewModel()
        return UINavigationController(rootViewController: invitationsVC)
    }()
    
    private lazy var searchViewController: UINavigationController = {
        let spotifyAuthService = DMSpotifyAuthService()
        let spotifySearchService = DMSpotifySearchService(authService: spotifyAuthService,
                                                          reachabilityService: self.reachabilityService)
        
        let spotifySongSearchViewModel = DMSpotifySongSearchViewModel(promptCoordinator: self,
                                                                      spotifySearchService: spotifySearchService)
        
        let spotifySearchVC = DMSpotifySongSearchViewController(withViewModel: spotifySongSearchViewModel)
        spotifySearchVC.setupForViewModel()
        return UINavigationController(rootViewController: spotifySearchVC)
    }()
    
    func beginCoordinating(withWindow window: UIWindow) {
        
        pageViewController.setViewControllers([managementViewController(forScene: .songs)],
                                              direction: .forward,
                                              animated: false,
                                              completion: nil)
        pageViewController.dataSource = self
        window.rootViewController = pageViewController
    }
    
    private func managementViewController(forScene scene: ManagementScene) -> UIViewController {
        switch scene {
        case .songs:
            return songsViewController
        case .invites:
            return invitesViewController
        case .search:
            return searchViewController
        }
    }
    
    private func scene(ofViewController viewController: UIViewController) -> ManagementScene? {
        if viewController is DMEventManagementViewController {
            return .songs
        }
        
        if viewController is DMEventInvitationsViewController {
            return .invites
        }
        
        if viewController is DMSpotifySongSearchViewController {
            return .search
        }
        
        return nil
    }
    
}

extension DMEventManagementSceneCoordinator: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let contentController = (viewController as? UINavigationController)?.viewControllers.first else {
            return nil
        }
        
        guard let scene = scene(ofViewController: contentController) else {
            return nil
        }
    
        guard let sceneIndex = scenes.index(of: scene) else {
            return nil
        }
        
        let newIndex = sceneIndex + 1
        
        guard newIndex != scenes.count else {
            return nil
        }
        
        return managementViewController(forScene: scenes[newIndex])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let contentController = (viewController as? UINavigationController)?.viewControllers.first else {
            return nil
        }
        
        guard let scene = scene(ofViewController: contentController) else {
            return nil
        }
        
        guard let sceneIndex = scenes.index(of: scene), sceneIndex != 0 else {
            return nil
        }
        
        return managementViewController(forScene: scenes[sceneIndex - 1])
    }
    
}

extension DMEventManagementSceneCoordinator: PromptCoordinating {
    
    func promptFor<Action : CustomStringConvertible>(_ message: String, cancelAction: Action, actions: [Action]?) -> Observable<Action> {
        return Observable.create { observer in
            let alertView = UIAlertController(title: "RxExample", message: message, preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: cancelAction.description, style: .cancel) { _ in
                observer.on(.next(cancelAction))
            })
            
            if let actions = actions {
                for action in actions {
                    alertView.addAction(UIAlertAction(title: action.description, style: .default) { _ in
                        observer.on(.next(action))
                    })
                }
            }
            
            self.currentViewController?.present(alertView, animated: true, completion: nil)
            
            return Disposables.create {
                alertView.dismiss(animated:false, completion: nil)
            }
        }
    }

}
