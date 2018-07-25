//
//  SearchInteractionViewModels.swift
//  Koel
//
//  Created by Mindaugas on 25/07/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import RxSwift

protocol TriggerObservingViewModelType {
    
    var offsetTrigger: Observable<()> { get }
    var refreshTrigger: Observable<()> { get }
    
}

protocol TriggerConsumingViewModelType {
    
    var offsetTriggerObserver: AnyObserver<()> { get }
    var refreshTriggerObserver: AnyObserver<()> { get }
    
}

class TriggersViewModel: TriggerConsumingViewModelType, TriggerObservingViewModelType {
    
    private var offsetTriggerRelay: PublishSubject<()> = PublishSubject()
    private var refreshTriggerRelay: PublishSubject<()> = PublishSubject()
    
    var offsetTrigger: Observable<()> {
        return offsetTriggerRelay.asObservable()
    }
    
    var refreshTrigger: Observable<()> {
        return refreshTriggerRelay.asObservable()
    }
    
    var offsetTriggerObserver: AnyObserver<()> {
        return offsetTriggerRelay.asObserver()
    }
    
    var refreshTriggerObserver: AnyObserver<()> {
        return refreshTriggerRelay.asObserver()
    }
    
}

protocol LoadingStateObservingViewModelType {
    
    var isLoading: Observable<Bool> { get }
    var isRefreshing: Observable<Bool> { get }
    
}

protocol LoadingStateConsumingViewModelType {
    
    var loading: AnyObserver<Bool> { get }
    var refreshing: AnyObserver<Bool> { get }
}

class LoadingStateViewModel: LoadingStateObservingViewModelType, LoadingStateConsumingViewModelType {
    
    private let isRefreshingRelay = BehaviorSubject(value: false)
    private let isLoadingRelay = BehaviorSubject(value: false)
    
    var loading: AnyObserver<Bool> {
        return self.isRefreshingRelay.asObserver()
    }
    
    var refreshing: AnyObserver<Bool> {
        return self.isLoadingRelay.asObserver()
    }
    
    var isRefreshing: Observable<Bool> {
        return self.isRefreshingRelay.asObservable()
    }
    
    var isLoading: Observable<Bool> {
        return self.isLoadingRelay.asObservable()
    }
    
}
