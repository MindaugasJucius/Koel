//
//  DMInitialLoadingViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 27/10/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift

typealias InitialFetch = (DMUser?, Error?) -> ()

protocol DMInitialLoadingViewModelType {
    
    var onInitialFetchComplete: InitialFetch { get }
    var userObservable: Observable<DMUser>? { get }
    
}

final class DMInitialLoadingViewModel: NSObject, DMInitialLoadingViewModelType {
    
    private var userVariable: Variable<DMUser>?
    lazy var userObservable: Observable<DMUser>? = self.userVariable?.asObservable()
    
    let onInitialFetchComplete: InitialFetch
    private let userManager: DMUserManager = DMUserManager()
    
    init(withInitialFetchCompletion initialFetchCompletion: @escaping InitialFetch) {
        self.onInitialFetchComplete = initialFetchCompletion
        super.init()
        fetchUser()
    }
    
    private func fetchUser() {
        userManager.fetchFullCurrentUserRecord(
            success: { [unowned self] user in
                self.userVariable?.value = user
            },
            failure: { error in
                
            }
        )
    }
    
}
