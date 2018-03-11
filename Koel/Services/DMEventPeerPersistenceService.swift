//
//  DMEventPeerPersistenceService.swift
//  Koel
//
//  Created by Mindaugas Jucius on 09/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import RxRealm
import MultipeerConnectivity

private let SelfPeerID = 0

struct DMEventPeerPersistenceService: DMEventPeerPersistenceServiceType {

    private let concurrentScheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS.background)
    
    private func withRealm<T>(_ operation: String, action: @escaping (Realm) throws -> T) -> Observable<T> {
        return Observable<T>
            .create { observer -> Disposable in
                do {
                    let realm = try Realm()
                    observer.onNext(try action(realm))
                } catch let error {
                    observer.onError(error)
                }
                return Disposables.create()
            }
            .subscribeOn(concurrentScheduler)
            .observeOn(MainScheduler.instance)
    }
    
    @discardableResult
    func store(peer: DMEventPeer) -> Observable<DMEventPeer> {
        
        return withRealm("creating peer") { realm -> ThreadSafeReference<DMEventPeer> in
            try realm.write {
                
                print("storing \(peer.peerID?.displayName) isSelf \(peer.isSelf) isHost \(peer.isHost) with uuid \(peer.uuid)")
                
                if let peerID = peer.peerID {
                    peer.peerIDData = NSKeyedArchiver.archivedData(withRootObject: peerID)
                }
                
                peer.primaryKeyRef = peer.uuid
                realm.add(peer, update: true)
            }

            return ThreadSafeReference(to: peer)
        }
        .flatMap { safePeerReference -> Observable<DMEventPeer> in
            return self.peerOnMainScheduler(
                fromReference: safePeerReference,
                peerID: peer.peerID,
                errorOnFailure: .peerCreationFailed
            )
        }
        
    }
    
    func delete(peer: DMEventPeer) -> Observable<Void> {
        _ = withRealm("deleting peer") { realm -> Void in
            guard let peerToDelete = realm.object(ofType: DMEventPeer.self, forPrimaryKey: peer.primaryKeyRef) else {
                throw DMEventPeerPersistenceServiceError.deletionFailed(peer)
            }
            
            try realm.write {
                realm.delete(peerToDelete)
            }
            print("deleted peer: \(String(describing: peer.peerID?.displayName)), primarykey: \(peerToDelete.primaryKeyRef)")
        }
        
        return .empty()
    }
    
    func peerExists(withPeerID peerID: MCPeerID) -> Observable<DMEventPeer> {
        return withRealm("checking if peer exists") { realm -> ThreadSafeReference<DMEventPeer>? in
            let allPeers = realm.objects(DMEventPeer.self).toArray()
            for peer in allPeers {
                guard let unarchivedPeerID = NSKeyedUnarchiver.unarchiveObject(with: peer.peerIDData) as? MCPeerID,
                 peerID == unarchivedPeerID else {
                    continue
                }
                peer.peerID = unarchivedPeerID
                return ThreadSafeReference(to: peer)
            }
            return nil
        }
        .flatMap { maybeSafePeerReference -> Observable<DMEventPeer> in
            guard let safePeerReference = maybeSafePeerReference else {
                return Observable.error(DMEventPeerPersistenceServiceError.peerDoesNotExist)
            }
            return self.peerOnMainScheduler(fromReference: safePeerReference, peerID: peerID, errorOnFailure: .existenceCheckFailed)
        }
        
    }
    
    // MARK: - Retrieved object updates
    @discardableResult
    func update(peer: DMEventPeer, updateBlock: @escaping PeerUpdate) -> Observable<DMEventPeer> {
        return withRealm("updating peer host status") { realm -> ThreadSafeReference<DMEventPeer> in
            guard let retrievedPeer = realm.object(ofType: DMEventPeer.self, forPrimaryKey: peer.primaryKeyRef) else {
                throw DMEventPeerPersistenceServiceError.updateFailed(peer)
            }
            
            try realm.write {
                realm.add(updateBlock(retrievedPeer), update: true)
            }
            
            return ThreadSafeReference(to: retrievedPeer)
        }
        .flatMap { safePeerReference -> Observable<DMEventPeer> in
            return self.peerOnMainScheduler(
                fromReference: safePeerReference,
                peerID: peer.peerID,
                errorOnFailure: .updateFailed(peer)
            )
        }
    }
    
}

// MARK: - Helpers
extension DMEventPeerPersistenceService {
    
    func peerOnMainScheduler(fromReference reference: ThreadSafeReference<DMEventPeer>?, peerID: MCPeerID?,
                             errorOnFailure: DMEventPeerPersistenceServiceError) -> Observable<DMEventPeer> {
        return Realm.objectOnMainSchedulerObservable(fromReference: reference, errorOnFailure: errorOnFailure)
            .map { resolvedPeer in
                resolvedPeer.peerID = peerID
                resolvedPeer.primaryKeyRef = resolvedPeer.uuid
                return resolvedPeer
            }
    }
    
}
