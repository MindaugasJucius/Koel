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

class SceneCoordinator: NSObject, SceneCoordinatorType {

    private let disposeBag = DisposeBag()
    
    private let navigationControllerStackObserver = PublishSubject<UIViewController>()
    
    fileprivate var window: UIWindow
    var currentViewController: UIViewController
    
    required init(window: UIWindow) {
        self.window = window
        currentViewController = window.rootViewController!
        super.init()
        observeStackChanges()
    }
    
    private func observeStackChanges() {
        navigationControllerStackObserver.subscribe(
            onNext: { [weak self] viewController in
                guard let this = self else {
                    return
                }
                this.currentViewController = viewController
            }
        ).disposed(by: disposeBag)
    }
    
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
            
            self.currentViewController.present(alertView, animated: true, completion: nil)

            return Disposables.create {
                alertView.dismiss(animated:false, completion: nil)
            }
        }
    }
    
    static func actualViewController(for viewController: UIViewController) -> UIViewController {
        if let navigationController = viewController as? UINavigationController {
            return navigationController.viewControllers.first!
        } else {
            return viewController
        }
    }
    
    private func navigationControllerInStack() -> UINavigationController? {
        if let currentNavigationController = currentViewController as? UINavigationController {
            return currentNavigationController
        } else if let currentVCsParent = currentViewController.navigationController {
            return currentVCsParent
        }
        return .none
    }
    
    @discardableResult
    func transition(to scene: Scene, type: SceneTransitionType) -> Observable<Void> {
        let subject = PublishSubject<Void>()
        let viewController = scene.viewController()
        
        switch type {
        case .root:
            currentViewController = SceneCoordinator.actualViewController(for: viewController)
            window.rootViewController = viewController
            subject.onCompleted()
        case .rootWithNavigationVC:
            currentViewController = SceneCoordinator.actualViewController(for: viewController)

            window.rootViewController = UINavigationController(rootViewController: currentViewController)
            subject.onCompleted()
        case .push:

            guard let navigationController = navigationControllerInStack() else {
                fatalError("Can't push a view controller without a current navigation controller")
            }
            
            let selector = #selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:))
            
            let observable = navigationController.rx.delegate
                .sentMessage(selector)
                .map { parameters in return parameters[1] as! UIViewController }
                .share()
            
            observable
                .subscribe(navigationControllerStackObserver.asObserver())
                .disposed(by: disposeBag)
            
            // one-off subscription to be notified when push completes
            _ = observable
                .map { _ in }
                .take(1)
                .bind(to: subject)
            
            navigationController.pushViewController(viewController, animated: true)
            currentViewController = SceneCoordinator.actualViewController(for: viewController)
            
        case .modal:
            currentViewController.present(viewController, animated: true) {
                subject.onCompleted()
            }
            currentViewController = SceneCoordinator.actualViewController(for: viewController)
        }
        return subject.asObservable()
    }
    
    @discardableResult
    func pop(animated: Bool) -> Observable<Void> {
        let subject = PublishSubject<Void>()
        if let presenter = currentViewController.presentingViewController {
            // dismiss a modal controller
            currentViewController.dismiss(animated: animated) {
                self.currentViewController = SceneCoordinator.actualViewController(for: presenter)
                subject.onNext(())
                subject.onCompleted()
            }
        } else if let navigationController = currentViewController.navigationController {
            // navigate up the stack
            // one-off subscription to be notified when pop complete
            _ = navigationController.rx.delegate
                .sentMessage(#selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)))
                .map { _ in }
                .take(1)
                .bind(to: subject)
            guard navigationController.popViewController(animated: animated) != nil else {
                fatalError("can't navigate back from \(currentViewController)")
            }
            currentViewController = SceneCoordinator.actualViewController(for: navigationController.viewControllers.last!)
        } else {
            fatalError("Not a modal, no navigation controller: can't navigate back from \(currentViewController)")
        }
        return subject.asObservable()
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
