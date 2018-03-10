//
//  DMEventPeerPersistenceServiceType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 09/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import MultipeerConnectivity

typealias PeerUpdate = (DMEventPeer) -> (DMEventPeer)

enum ContextKeys {

    case reconnect
    case isHost
    case uuid(String)
    
    var dictionary: [String:String] {
        switch self {
        case .uuid(let value):
            return [self.rawValue: value]
        default:
            return [self.rawValue: "true"]
        }
    }
}

extension ContextKeys: RawRepresentable {

    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "reconnect":
            self = .reconnect
        case "isHost":
            self = .isHost
        case (let value):
            self = .uuid(value)
        }
    }
    
    var rawValue: RawValue {
        switch self {
        case .isHost:
            return "isHost"
        case .reconnect:
            return "reconnect"
        case .uuid(_):
            return "uuid"
        }
    }
}

extension ContextKeys: Equatable {
    static func == (lhs: ContextKeys, rhs: ContextKeys) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension ContextKeys: Hashable {
    var hashValue: Int {
        return self.rawValue.hashValue
    }
}

enum DMEventPeerPersistenceServiceError: Error {
    case peerCreationFailed
    case fetchingFailed
    case existenceCheckFailed
    case peerDoesNotExist
    case updateFailed(DMEventPeer)
    case deletionFailed(DMEventPeer)
}

protocol DMEventPeerPersistenceServiceType {

    @discardableResult
    func store(peer: DMEventPeer) -> Observable<DMEventPeer>

    func delete(peer: DMEventPeer) -> Observable<Void>

    @discardableResult
    func peerExists(withPeerID peerID: MCPeerID) -> Observable<DMEventPeer>
    
    @discardableResult
    func update(peer: DMEventPeer, updateBlock: @escaping PeerUpdate) -> Observable<DMEventPeer>

}
