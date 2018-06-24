//
//  SceneCoordinator.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum Scene {
    case search(DMEventSearchViewModel)
}

private extension Scene {
    func viewController() -> UIViewController {
        switch self {
        //MARK: Shared
        case .search(let viewModel):
            let eventSearchVC = DMEventSearchViewController(withViewModel: viewModel)
            eventSearchVC.setupForViewModel()
            return eventSearchVC
       }
    }
}

class SceneCoordinator: NSObject, SceneCoordinatorType {

    private let disposeBag = DisposeBag()    
    private let window: UIWindow

    required init(window: UIWindow) {
        self.window = window
        super.init()
    }
    
    @discardableResult
    func transition(to scene: Scene, type: SceneTransitionType) -> Observable<Void> {
        let subject = PublishSubject<Void>()
        let viewController = scene.viewController()
        
        switch type {
        case .rootWithNavigationVC:
            window.rootViewController = UINavigationController(rootViewController: viewController)
            subject.onCompleted()
            return subject.asObservable()
        }
    }
    
}

extension SceneCoordinator: CoordinatorTransitioning {

    func transitionToHostScene() -> Observable<Void> {
        let managementCoordinator = DMEventSceneCoordinator()
        return managementCoordinator.beginCoordinating(withWindow: window)
    }
    
    func transitionToParticipationScene(withMultipeerService multipeerService: DMEventMultipeerService,
                                        eventHost: DMEventPeer) -> Observable<Void> {
        let participationCoordinator = DMEventSceneCoordinator(withMultipeerService: multipeerService,
                                                               eventHost: eventHost)
        return participationCoordinator.beginCoordinating(withWindow: window)
    }
}
