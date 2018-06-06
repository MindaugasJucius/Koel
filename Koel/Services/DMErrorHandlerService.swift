//
//  DMErrorHandlerService.swift
//  Koel
//
//  Created by Mindaugas on 03/06/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift

protocol DMErrorHandlerServiceType {
    
    init(sceneCoordinator: SceneCoordinatorType)

    var retryHandler: (Observable<Error>) -> Observable<Int> { get }
}

class DMErrorHandlerService: DMErrorHandlerServiceType {
    
    private let maxRetryAttempts = 4
    
    private let sceneCoordinator: SceneCoordinatorType
    
    required init(sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
    }
    
    lazy var retryHandler: (Observable<Error>) -> Observable<Int> = {
        return { error in
            return error.enumerated().flatMap { (attempt, error) -> Observable<Int> in
                if attempt == self.maxRetryAttempts {
                    return Observable.error(error)
                }
                
                let nsError = error as NSError
                switch nsError.code {
                case -1009:
                    print("no internet")
                    return self.sceneCoordinator.promptFor(nsError.localizedDescription, cancelAction: "cancel", actions: nil)
                        .filter { $0 == "cancel" }
                        .map { _ in 1 }
                default:
                    print("== retrying after \(attempt + 1) seconds ==")
                    return Observable<Int>.timer(Double(attempt + 1), scheduler: MainScheduler.instance).take(1)
                }
            }
        }
    }()
    
}
