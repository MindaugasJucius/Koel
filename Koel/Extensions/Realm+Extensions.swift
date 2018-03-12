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

private let concurrentScheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS.background)

extension Realm {

    static func withRealm<T>(
        operation: String,
        error: Swift.Error,
        scheduler: SchedulerType = concurrentScheduler,
        nilResultHandler: ((AnyObserver<ThreadSafeReference<T>>) -> ())? = nil,
        action: @escaping (Realm) throws -> T?) -> Observable<T> {
        return Observable<ThreadSafeReference<T>>
            .create { observer -> Disposable in
                print("performing operation: \(operation)")
                do {
                    let realm = try Realm()
                    if let result = try action(realm) {
                        observer.onNext(ThreadSafeReference(to: result))
                    } else {
                        nilResultHandler?(observer)
                    }
                } catch {
                    observer.onError(error)
                }
                observer.onCompleted()
                return Disposables.create()
            }
            .subscribeOn(scheduler)
            .flatMap { threadSafeReferenceToResult -> Observable<T> in
                return Realm.safeObject(
                    resolveOnScheduler: MainScheduler.instance,
                    fromReference: threadSafeReferenceToResult,
                    errorOnFailure: error
                )
            }
    }
    
    // resolves safe object reference on subscribeOn scheduler
    static func safeObject<T>(
        resolveOnScheduler: SchedulerType,
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
        .subscribeOn(resolveOnScheduler)
    }
    
}
