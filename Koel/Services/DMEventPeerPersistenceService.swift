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

        let result = Realm.withRealm(
            operation: "creating peer",
            error: DMEventPeerPersistenceServiceError.peerCreationFailed) { (realm) -> DMEventPeer in
                try realm.write {
                    
                    print("storing \(peer.peerID?.displayName) isSelf \(peer.isSelf) isHost \(peer.isHost) with uuid \(peer.uuid)")
                    
                    if let peerID = peer.peerID {
                        peer.peerIDData = NSKeyedArchiver.archivedData(withRootObject: peerID)
                    }
                    
                    peer.primaryKeyRef = peer.uuid
                    realm.add(peer, update: true)
                }
                return peer
            }
        
        return result.flatMap { (resolvedPeer) -> Observable<DMEventPeer> in
            resolvedPeer.peerID = peer.peerID
            resolvedPeer.primaryKeyRef = resolvedPeer.uuid
            return Observable.just(resolvedPeer)
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
    
    func peerExists(withUUID uuid: String) -> Observable<DMEventPeer> {
        let result = Realm.withRealm(
            operation: "checking if peer exists",
            error: DMEventPeerPersistenceServiceError.existenceCheckFailed,
            nilResultHandler: { observer in
                observer.onError(DMEventPeerPersistenceServiceError.peerDoesNotExist)
            },
            action: { realm -> DMEventPeer? in
                let uuidPredicate = NSPredicate(format: "uuid = %@", uuid)
                return realm.objects(DMEventPeer.self).filter(uuidPredicate).first
            }
        )
        
        return result.flatMap { (resolvedPeer) -> Observable<DMEventPeer> in
            if let unarchivedPeerID = NSKeyedUnarchiver.unarchiveObject(with: resolvedPeer.peerIDData) as? MCPeerID {
                resolvedPeer.peerID = unarchivedPeerID
            }
            resolvedPeer.primaryKeyRef = resolvedPeer.uuid
            return Observable.just(resolvedPeer)
        }
        
    }
    
    // MARK: - Retrieved object updates
    @discardableResult
    func update(peer: DMEventPeer, updateBlock: @escaping PeerUpdate) -> Observable<DMEventPeer> {
        return Realm.withRealm(
            operation: "updating peer",
            error: DMEventPeerPersistenceServiceError.updateFailed(peer)) { realm -> DMEventPeer in
                guard let retrievedPeer = realm.object(ofType: DMEventPeer.self, forPrimaryKey: peer.primaryKeyRef) else {
                    throw DMEventPeerPersistenceServiceError.updateFailed(peer)
                }
                
                try realm.write {
                    realm.add(updateBlock(retrievedPeer), update: true)
                }
                
                return retrievedPeer
            }
            .flatMap { (resolvedPeer) -> Observable<DMEventPeer> in
                resolvedPeer.peerID = peer.peerID
                resolvedPeer.primaryKeyRef = resolvedPeer.uuid
                return Observable.just(resolvedPeer)
            }
    }
    
}
