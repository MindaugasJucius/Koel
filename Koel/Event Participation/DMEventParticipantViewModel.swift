//
//  DMEventManagementViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 04/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift
import Action

private let HostCacheKey = "HostCacheKey"

struct DMEventParticipantViewModel {
    
    private let disposeBag = DisposeBag()
    
    private let multipeerService: DMEventMultipeerService
    private let host: DMEventPeer
    
    var hostExists: Observable<Bool> {
        return multipeerService.connectedPeers().map { peers in
            let hostExists = peers.filter { $0.peerID == self.host.peerID }.count == 1
            print("hostExists observable \(hostExists)")
            return hostExists
        }
    }
    
    private var hostNearby: Observable<Bool> {
        return multipeerService.nearbyFoundHostPeers().map { peers in
            print("hostNearby observable \(peers.map { $0.peerDeviceDisplayName })")
            return peers.filter { $0.peerID == self.host.peerID }.count == 1
        }
    }
    
    private var incommingHostReconnectInvitations: Observable<(Bool) -> ()> {
        return multipeerService
            .incomingPeerInvitations()
            .filter { (client, context, handler) in
                let eventPeer = DMEventPeer.init(withContext: context as? [String : String], peerID: client)
                return eventPeer.isHost && eventPeer.peerID == self.host.peerID
            }
            .map { (_, _, handler) in
                return handler
            }
    }
    
    private var didEnterBackgroundNotificationHandler: (Notification) -> () {
        return { (notification: Notification) in
            guard notification.name == Notifications.didEnterBackground else {
                return
            }
            self.multipeerService.disconnect()
        }
    }
    
    lazy var requestReconnect: Action<(DMEventPeer), Void> = { this in
        return Action(
            workFactory: { (eventPeer: DMEventPeer) in
                print("requesting reconnection for \(eventPeer.peerDeviceDisplayName)")
                let reconnectContext = MultipeerEventContexts.participantReconnect
                return this.multipeerService.connect(eventPeer.peerID, context: reconnectContext)
            }
        )
    }(self)
    
    init(withMultipeerService multipeerService: DMEventMultipeerService, withHost host: DMEventPeer) {
        self.multipeerService = multipeerService
        self.host = host
        
        store(host: host)

        incommingHostReconnectInvitations
            .subscribe(onNext: { handler in
                    handler(true)
                }
            )
            .disposed(by: disposeBag)
        
        let hostDisconnectedObservable = multipeerService
            .connectedPeers()
            .map { connections in
            return connections.filter { $0.peerID == host.peerID }.count == 0 // true if current host is not connected
        }
        
        hostNearby
            .filter { $0 }
            .withLatestFrom(hostDisconnectedObservable)
            .filter { hostDisconnected in
                print("is host disconnected \(hostDisconnected)")
                return hostDisconnected
            }
            .map { _ in host }
            .subscribe(requestReconnect.inputs)
            .disposed(by: disposeBag)
    
        NotificationCenter.default.addObserver(
            forName: Notifications.didEnterBackground,
            object: nil,
            queue: nil,
            using: didEnterBackgroundNotificationHandler
        )
    }
    
    private func store(host: DMEventPeer) {
        guard host.isHost else {
            return
        }
        
        let hostData = NSKeyedArchiver.archivedData(withRootObject: host)
        UserDefaults.standard.set(hostData, forKey: HostCacheKey)
    }
    
}
