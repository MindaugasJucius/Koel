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
    
    private func withRealm<T>(_ operation: String, action: (Realm) throws -> T) -> T? {
        do {
            let realm = try Realm()
            return try action(realm)
        } catch let err {
            print("Failed \(operation) realm with error: \(err)")
            return nil
        }
    }
    
    @discardableResult
    func store(peer: DMEventPeer) throws -> DMEventPeer {
        let result = withRealm("creating peer") { realm -> DMEventPeer in
            try realm.write {
                peer.id = (realm.objects(DMEventPeer.self).max(ofProperty: "id") ?? 0) + 1
                if let peerID = peer.peerID {
                    peer.peerIDData = NSKeyedArchiver.archivedData(withRootObject: peerID)
                }
                realm.add(peer)
            }
            return peer
        }
        
        guard let storedPeer = result else {
            throw DMEventPeerPersistenceServiceError.peerCreationFailed
        }
        
        return storedPeer
    }
    
    func storePeer(withContext: [String: String]?, peerID: MCPeerID) throws -> DMEventPeer {
        return DMEventPeer()
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
    
}
