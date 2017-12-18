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

struct DMEventPeerPersistenceService: DMEventPeerPersistenceServiceType {
    
    private let realmDispatchQueue = DispatchQueue(
        label: "peer-realm-persistence-queue",
        qos: .background,
        attributes: .concurrent
    )
    
    private func withRealm<T>(_ operation: String, action: (Realm) throws -> T) -> T? {
        do {
            let result = try self.realmDispatchQueue.sync { () -> T in
                let realm = try Realm()
                return try action(realm)
            }
            return result
        } catch let err {
            print("Failed \(operation) realm with error: \(err)")
            return nil
        }
    }
    
    func store(peer: DMEventPeer) -> Observable<DMEventPeer> {
        let result = withRealm("creating peer") { realm -> ThreadSafeReference<DMEventPeer> in
            try realm.write {
                peer.id = (realm.objects(DMEventPeer.self).max(ofProperty: "id") ?? 0) + 1
                if let peerID = peer.peerID {
                    peer.peerIDData = NSKeyedArchiver.archivedData(withRootObject: peerID)
                }
                realm.add(peer)
            }

            return ThreadSafeReference(to: peer)
        }
        
        return objectObservable(fromReference: result, peerID: peer.peerID, errorOnFailure: .peerCreationFailed).filterNil()
    }
    
    func delete(peer: DMEventPeer) throws {
        _ = withRealm("deleting peer") { realm -> Void in
            guard let peerToDelete = realm.object(ofType: DMEventPeer.self, forPrimaryKey: peer.primaryKeyRef) else {
                throw DMEventPeerPersistenceServiceError.deletionFailed(peer)
            }
            
            try realm.write {
                realm.delete(peerToDelete)
            }
            print("deleted peer: \(String(describing: peer.peerID?.displayName)), primarykey: \(peerToDelete.primaryKeyRef)")
        }
    }
    
    func peerExists(withPeerID peerID: MCPeerID) -> Observable<DMEventPeer?> {
        let threadSafeReference = withRealm("checking if peer exists") { realm -> ThreadSafeReference<DMEventPeer>? in
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
        
//        guard let threadSafeReference = result else {
//            return Observable.empty()
//        }

        return objectObservable(
            fromReference: threadSafeReference!,
            peerID: peerID,
            errorOnFailure: .existenceCheckFailed
        )
    }
    
    @discardableResult
    func retrieveHost() -> DMEventPeer? {
        let result = withRealm("getting host peer") { realm -> DMEventPeer? in
            let selfPeer = realm.objects(DMEventPeer.self).filter("isHost == YES").first
            return selfPeer
        }
        return result ?? nil
    }
    
    @discardableResult
    func retrieveSelf() -> DMEventPeer? {
        let result = withRealm("getting self peer") { realm -> DMEventPeer? in
            let selfPeer = realm.objects(DMEventPeer.self).filter("isSelf == true").first
            if let peerIDData = selfPeer?.peerIDData {
                selfPeer?.peerID = NSKeyedUnarchiver.unarchiveObject(with: peerIDData) as? MCPeerID
            }

            print(selfPeer?.peerID)
            print(selfPeer?.peerIDData)
            print(selfPeer?.isSelf)
            return selfPeer
        }
        return result ?? nil
    }
    
    func peers() -> Observable<Results<DMEventPeer>> {
        let result = withRealm("getting all peers") { realm -> Observable<Results<DMEventPeer>> in
            let peers = realm.objects(DMEventPeer.self).filter("isSelf == NO")
            return Observable.collection(from: peers)
        }
        return result ?? .empty()
    }
    
    //MARK: - Retrieved object updates
    
    func update(peer: DMEventPeer, toConnectedState isConnected: Bool) -> Observable<DMEventPeer> {
        let result = withRealm("updating peer connectivity state") { realm -> ThreadSafeReference<DMEventPeer> in
            guard let retrievedPeer = realm.object(ofType: DMEventPeer.self, forPrimaryKey: peer.primaryKeyRef) else {
                throw DMEventPeerPersistenceServiceError.updateFailed(peer)
            }
            
            try realm.write {
                retrievedPeer.isConnected = isConnected
            }
            return ThreadSafeReference(to: retrievedPeer)
        }
        
        return objectObservable(fromReference: result, peerID: peer.peerID, errorOnFailure: .updateFailed(peer)).filterNil()
    }
    
    //MARK: - Helpers
    
    private func objectObservable<T: Object>(fromReference reference: ThreadSafeReference<T>?, peerID: MCPeerID?, errorOnFailure: DMEventPeerPersistenceServiceError) -> Observable<T?> {
        return Observable<T?>.create { observer in
            
            if let threadSafePeerRef = reference {
                do {
                    let realm = try Realm()
                    if let resolvedPeer = realm.resolve(threadSafePeerRef) {
//                        resolvedPeer.peerID = peerID
//                        resolvedPeer.primaryKeyRef = resolvedPeer.id
                        observer.onNext(resolvedPeer)
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
        }.observeOn(MainScheduler.instance)
    }
    
}

