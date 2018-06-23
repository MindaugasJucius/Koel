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

class DMEventManagementSceneCoordinator: RootTransitioning {

    private var currentViewController: UIViewController?
    private let reachabilityService = try! DefaultReachabilityService()
    
    init() {
        
    }
    
    func transitionToEventManagement() -> Observable<Void> {
        
        return .just(())
    }
    
    func beginCoordinating(withWindow window: UIWindow) {
        let multipeerService = DMEventMultipeerService(asEventHost: true)
        
        let songSharingViewModel = DMEventSongSharingViewModel(
            songPersistenceService: DMEventSongPersistenceService(selfPeer: multipeerService.myEventPeer),
            reachabilityService: self.reachabilityService,
            songSharingService: DMEntitySharingService(),
            multipeerService: multipeerService
        )
        
        let manageEventViewModel = DMEventManagementViewModel(
            multipeerService: multipeerService,
            reachabilityService: self.reachabilityService,
            promptCoordinator: self,
            songsRepresenter: songSharingViewModel,
            songsEditor: songSharingViewModel
        )
        
        let spotifyAuthService = DMSpotifyAuthService()
        let spotifySearchService = DMSpotifySearchService(authService: spotifyAuthService,
                                                          reachabilityService: self.reachabilityService)
        
        let spotifySongSearchViewModel = DMSpotifySongSearchViewModel(
            promptCoordinator: self,
            spotifySearchService: spotifySearchService
        )
        
        let invitationsViewModel = DMEventInvitationsViewModel(
            multipeerService: multipeerService
        )
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
