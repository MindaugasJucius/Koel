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
import os.log

enum DMEntityError: Error {
    case updateFailed(DMEntity)
}

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
                os_log("performing operation: %@", log: OSLog.default, type: OSLogType.info, operation)
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
    
    static func withRealmArray<T>(
        operation: String,
        error: Swift.Error,
        scheduler: SchedulerType = concurrentScheduler,
        nilResultHandler: ((AnyObserver<[ThreadSafeReference<T>]>) -> ())? = nil,
        action: @escaping (Realm) throws -> [T]?) -> Observable<[T]> {
        return Observable<[ThreadSafeReference<T>]>
            .create { observer -> Disposable in
                os_log("performing operation: %@", log: OSLog.default, type: OSLogType.info, operation)
                do {
                    let realm = try Realm()
                    if let result = try action(realm) {
                        let threadSafeReferenceArray = result.map { ThreadSafeReference(to: $0) }
                        observer.onNext(threadSafeReferenceArray)
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
            .flatMap { threadSafeReferenceArray -> Observable<T> in
                let observables = threadSafeReferenceArray.map { (threadSafeReference) -> Observable<T> in
                    Realm.safeObject(
                        resolveOnScheduler: MainScheduler.instance,
                        fromReference: threadSafeReference,
                        errorOnFailure: error
                    )
                }
                return Observable.merge(observables)
            }
            .reduce([], accumulator: { (array, song) -> [T] in
                return array + [song]
            })

    }
    
    // resolves safe object reference on scheduler
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
    
    static func clearRealm() -> Observable<Void> {
        return Observable<Void>.create { observer in
            do {
                let realm = try Realm()
                try realm.write {
                    realm.deleteAll()
                }
            } catch let error {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
    
    static func update<T>(entity: T,
                          operation: String = "updating entity: \(T.self)",
                          onScheduler scheduler: SchedulerType = concurrentScheduler,
                          updateBlock: @escaping (T) -> (T)) -> Observable<T> where T: DMEntity, T: Object {
        return Realm.withRealm(
            operation: operation,
            error: DMEntityError.updateFailed(entity),
            scheduler: scheduler) { realm -> T in
                guard let retrievedEntity = realm.object(ofType: T.self, forPrimaryKey: entity.primaryKeyRef) else {
                    throw DMEntityError.updateFailed(entity)
                }
                
                try realm.write {
                    realm.add(updateBlock(retrievedEntity), update: true)
                }
                
                return retrievedEntity
            }
            .flatMap { resolvedEntity -> Observable<T> in
                var entity = resolvedEntity
                entity.primaryKeyRef = resolvedEntity.uuid
                return Observable.just(entity)
        }
    }
    
}
