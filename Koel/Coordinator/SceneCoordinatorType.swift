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
    // you can extend this to add animated transition types,
    // interactive transitions and even child view controllers!
    
    case root       // make view controller the root view controller
    case rootWithNavigationVC
    case push       // push view controller to navigation stack
    case modal      // present view controller modally
}

protocol SceneCoordinatorType {
    init(window: UIWindow)
    
    var currentViewController: UIViewController { get }
    
    /// transition to another scene
    @discardableResult
    func transition(to scene: Scene, type: SceneTransitionType) -> Observable<Void>
    
    /// pop scene from navigation stack or dismiss current modal
    @discardableResult
    func pop(animated: Bool) -> Observable<Void>
}

extension SceneCoordinatorType {
    @discardableResult
    func pop() -> Observable<Void> {
        return pop(animated: true)
    }
}

