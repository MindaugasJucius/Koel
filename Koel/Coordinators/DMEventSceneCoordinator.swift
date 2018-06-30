//
//  EventManagementSceneCoordinator.swift
//  Koel
//
//  Created by Mindaugas on 23/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift
import Action

protocol RootTransitioning {
    func beginCoordinating(withWindow window: UIWindow) -> Observable<Void>
}

private enum ManagementScene {
    case invites
    case songs
    case search
}

class DMEventSceneCoordinator: NSObject {

    private var currentViewController: UIViewController?
    private let reachabilityService = try! DefaultReachabilityService()
    private let multipeerService: DMEventMultipeerService
    private let isEventHost: Bool
    
    private lazy var pageViewController: UIPageViewController = {
        let pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                      navigationOrientation: .horizontal,
                                                      options: nil)
        pageViewController.view.backgroundColor = .white
        return pageViewController
    }()
    
    private let scenes: [ManagementScene] = [.invites, .songs, .search]
    private lazy var scenesViewControllerDict: [ManagementScene: UIViewController] = [.invites: invitesViewController,
                                                                                      .songs: songsViewController,
                                                                                      .search: searchViewController]
    
    init(withMultipeerService multipeerService: DMEventMultipeerService = DMEventMultipeerService(asEventHost: true),
         asHost: Bool = true) {
        self.multipeerService = multipeerService
        self.isEventHost = asHost
        super.init()
    }
    
    convenience init(withMultipeerService multipeerService: DMEventMultipeerService, eventHost: DMEventPeer) {
        self.init(withMultipeerService: multipeerService, asHost: false)
        participateEventViewModel = DMEventParticipationViewModel(host: eventHost,
                                                                  multipeerService: multipeerService,
                                                                  songsSectionsRepresenter: songSharingViewModel,
                                                                  songsEditor: songSharingViewModel)
    }
    
    //MARK: - View Models
    
    private lazy var songPersistenceService = DMEventSongPersistenceService(selfPeer: multipeerService.myEventPeer)
    
    private lazy var songSharingViewModel = DMEventSongSharingViewModel(songPersistenceService: songPersistenceService,
                                                                        reachabilityService: self.reachabilityService,
                                                                        songSharingService: DMEntitySharingService(),
                                                                        multipeerService: multipeerService)
    
    private lazy var manageEventViewModel = DMEventManagementViewModel(multipeerService: multipeerService,
                                                                       reachabilityService: self.reachabilityService,
                                                                       promptCoordinator: self,
                                                                       songsRepresenter: songSharingViewModel,
                                                                       songsEditor: songSharingViewModel)
    
    private var participateEventViewModel: DMEventParticipationViewModel?
    
    //MARK: - Shared Observables
    
    private func onQueueSelectedSongs() -> Action<[DMEventSong], Void> {
        return Action(workFactory: { songs -> Observable<Void> in
            return self.songPersistenceService
                .store(songs: songs)
                .filter { !$0.isEmpty }
                .share(withMultipeerService: self.multipeerService, sharingService: DMEntitySharingService<[DMEventSong]>())
                .flatMap { return self.transition(toManagementScene: .songs, animated: true) }
        })
    }
    
    //MARK: - Controllers
    
    private lazy var songsViewController: UINavigationController = {
        var songsViewController: UIViewController
        if isEventHost {
            let managementViewController = DMEventManagementViewController(withViewModel: manageEventViewModel,
                                                                           themeManager: ThemeManager.shared)
            managementViewController.setupForViewModel()
            songsViewController = managementViewController
        } else {
            //TODO: oops
            let participationViewController = DMEventParticipationViewController(withViewModel: participateEventViewModel!)
            participationViewController.setupForViewModel()
            songsViewController = participationViewController
        }

        return UINavigationController(rootViewController: songsViewController)
    }()
    
    private lazy var invitesViewController: UINavigationController = {
        let invitationsViewModel = DMEventInvitationsViewModel(multipeerService: multipeerService)
        
        let invitationsVC = DMEventInvitationsViewController(withViewModel: invitationsViewModel)
        invitationsVC.setupForViewModel()
        return UINavigationController(rootViewController: invitationsVC)
    }()
    
    private lazy var searchViewController: UINavigationController = {
        let spotifyAuthService = DMSpotifyAuthService(promptCoordinator: self)
        let spotifySearchService = DMSpotifySearchService(authService: spotifyAuthService,
                                                          reachabilityService: self.reachabilityService)
        
        let spotifySongSearchViewModel = DMSpotifySongSearchViewModel(promptCoordinator: self,
                                                                      spotifySearchService: spotifySearchService,
                                                                      onQueueSelectedSongs: onQueueSelectedSongs())
        
        let spotifySearchVC = DMSpotifySongSearchViewController(withViewModel: spotifySongSearchViewModel,
                                                                themeManager: ThemeManager.shared)
        spotifySearchVC.setupForViewModel()
        return UINavigationController(rootViewController: spotifySearchVC)
    }()
    
}

extension DMEventSceneCoordinator: RootTransitioning {
    
    func beginCoordinating(withWindow window: UIWindow) -> Observable<Void> {
        window.rootViewController = pageViewController
        pageViewController.dataSource = self
        
        return transition(toManagementScene: .songs, animated: false)
    }
    
}

extension DMEventSceneCoordinator {
    
    private func transition(toManagementScene scene: ManagementScene, animated: Bool) -> Observable<Void> {
        let subject = PublishSubject<Void>()
        
        guard let viewController = scenesViewControllerDict[scene] else {
            return .empty()
        }
        
        pageViewController.setViewControllers([viewController], direction: .reverse, animated: animated) { _ in
            subject.onCompleted()
        }
        
        return subject
    }
    
}

extension DMEventSceneCoordinator: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let sceneIndex = currentSceneIndex(ofViewController: viewController) else {
            return nil
        }
        
        let newIndex = sceneIndex + 1
        
        guard newIndex != scenes.count else {
            return nil
        }

        let newScene = scenes[newIndex]
        return scenesViewControllerDict[newScene]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let sceneIndex = currentSceneIndex(ofViewController: viewController) else {
            return nil
        }
        
        guard sceneIndex != 0 else {
            return nil
        }
        
        let newScene = scenes[sceneIndex - 1]
        return scenesViewControllerDict[newScene]
    }
    
    private func currentSceneIndex(ofViewController viewController: UIViewController) -> Int? {
        let sceneForCurrentVC = scenesViewControllerDict.first { $0.value.isEqual(viewController) }?.key
        guard let scene = sceneForCurrentVC else {
            return nil
        }
        
        return scenes.index(of: scene)
    }
    
}

extension DMEventSceneCoordinator: PromptCoordinating {
    
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
            
            self.pageViewController.present(alertView, animated: true, completion: nil)
            
            return Disposables.create {
                alertView.dismiss(animated:false, completion: nil)
            }
        }
    }

}
