//
//  Realm+Rx.swift
//  Koel
//
//  Created by Mindaugas Jucius on 19/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

extension Realm {
    
    static func safeObject<T>(
        observeOn: SchedulerType,
        subscribeOn: SchedulerType,
        fromReference reference: ThreadSafeReference<T>?,
        errorOnFailure: Swift.Error) -> Observable<T> {
        
        return Observable<T>.create { observer in
            if let threadSafeRef = reference {
                do {
                    let realm = try Realm()
                    if let resolvedObject = realm.resolve(threadSafeRef) {
                        observer.onNext(resolvedObject)
                    }
                } catch {
                    observer.onError(errorOnFailure)
                }
            }
            observer.onCompleted()
            return Disposables.create()
        }
        .observeOn(observeOn)
        .subscribeOn(subscribeOn)
    }
    
    static func objectOnMainSchedulerObservable<T>(fromReference reference: ThreadSafeReference<T>?, errorOnFailure: Swift.Error) -> Observable<T> {

        return Observable<T>.create { observer in
            if let threadSafeRef = reference {
                do {
                    let realm = try Realm()
                    if let resolvedObject = realm.resolve(threadSafeRef) {
                        observer.onNext(resolvedObject)
                    }
                } catch {
                    observer.onError(errorOnFailure)
                }
            }
            observer.onCompleted()
            return Disposables.create()
        }
        .observeOn(MainScheduler.instance)
        .subscribeOn(MainScheduler.instance)
    }

    static func deleteAll<T: Object>(ofType type: T) -> Observable<Void> {
        return .empty()
    }
    
}
