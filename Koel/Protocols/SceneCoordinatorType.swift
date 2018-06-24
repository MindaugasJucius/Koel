//
//  SceneCoordinatorType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift

enum SceneTransitionType {
    case rootWithNavigationVC
}

protocol CoordinatorTransitioning {

    func transitionToHostScene() -> Observable<Void>
    func transitionToParticipationScene(withMultipeerService multipeerService: DMEventMultipeerService,
                                        eventHost: DMEventPeer) -> Observable<Void>
}

protocol PromptCoordinating {

    func promptFor<Action : CustomStringConvertible>(_ message: String, cancelAction: Action, actions: [Action]?) -> Observable<Action>
}

protocol SceneCoordinatorType {
    init(window: UIWindow)
        
    /// transition to another scene
    @discardableResult
    func transition(to scene: Scene, type: SceneTransitionType) -> Observable<Void>
}

