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

private let peerPersistenceScheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS.background)

struct DMEventPeerPersistenceService: DMEventPeerPersistenceServiceType {
    
    @discardableResult
    func store(peer: DMEventPeer) -> Observable<DMEventPeer> {

        let result = Realm.withRealm(
            operation: "creating peer",
            error: DMEventPeerPersistenceServiceError.peerCreationFailed,
            scheduler: peerPersistenceScheduler) { (realm) -> DMEventPeer in
                try realm.write {
                    
                    print("storing peer: isSelf \(peer.isSelf) isHost \(peer.isHost) with uuid \(peer.uuid)")
                    
                    if let peerID = peer.peerID {
                        peer.peerIDData = NSKeyedArchiver.archivedData(withRootObject: peerID)
                    }
                    
                    realm.add(peer, update: true)
                }
                peer.primaryKeyRef = peer.uuid
                return peer
            }
        
        return result.flatMap { (resolvedPeer) -> Observable<DMEventPeer> in
            resolvedPeer.peerID = peer.peerID
            resolvedPeer.primaryKeyRef = resolvedPeer.uuid
            return Observable.just(resolvedPeer)
        }
       
    }
    
    func peerExists(withUUID uuid: String) -> Observable<DMEventPeer> {
        let result = Realm.withRealm(
            operation: "checking if peer exists",
            error: DMEventPeerPersistenceServiceError.existenceCheckFailed,
            scheduler: peerPersistenceScheduler,
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
        return Realm.update(entity: peer,
                            onScheduler: peerPersistenceScheduler,
                            updateBlock: updateBlock)
                    .flatMap { eventPeer -> Observable<DMEventPeer> in
                        eventPeer.peerID = peer.peerID
                        return Observable.just(eventPeer)
                    }
        
    }
    
}
