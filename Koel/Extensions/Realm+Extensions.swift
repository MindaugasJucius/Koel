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
    
    static func objectOnMainSchedulerObservable<T: Object>(fromReference reference: ThreadSafeReference<T>?, errorOnFailure: DMEventPeerPersistenceServiceError) -> Observable<T> {
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

    static func optionalObjectOnMainSchedulerObservable<T: Object>(fromReference reference: ThreadSafeReference<T>?, errorOnFailure: DMEventPeerPersistenceServiceError) -> Observable<T?> {
        return Observable<T?>.create { observer in
            if let threadSafeRef = reference {
                do {
                    let realm = try Realm()
                    if let resolvedObject = realm.resolve(threadSafeRef) {
                        observer.onNext(resolvedObject)
                    } else {
                        observer.onNext(nil)
                    }
                } catch {
                    observer.onError(errorOnFailure)
                }
            } else {
                observer.onNext(nil)
            }
            observer.onCompleted()
            return Disposables.create()
        }
        .observeOn(MainScheduler.instance)
        .subscribeOn(MainScheduler.instance)
    }
    
}
