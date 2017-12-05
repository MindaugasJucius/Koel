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

struct DMEventManagementViewModel {
    
    private let disposeBag = DisposeBag()
    
    private let multipeerService: DMEventMultipeerService
    private let host: DMEventPeer
    
    var hostExists: Observable<Bool> {
        return multipeerService.connectedPeers().map { peers in
            return peers.filter { $0.peerID == self.host.peerID }.count == 1
        }
    }
    
    private var hostNearby: Observable<Bool> {
        return multipeerService.nearbyFoundHostPeers().map { peers in
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
    
    private var didBecomeActiveNotificationHandler: (Notification) -> () {
        return { (notification: Notification) in
            guard notification.name == Notifications.didBecomeActive else {
                return
            }
            self.hostNearby
                .filter { $0 }
                .map { _ in self.host }
                .subscribe(self.requestReconnect().inputs)
                .disposed(by: self.disposeBag)
        }
    }
    
    init(withMultipeerService multipeerService: DMEventMultipeerService, withHost host: DMEventPeer) {
        self.multipeerService = multipeerService
        self.host = host
        
        store(host: host)
        
        multipeerService.latestConnectedPeer()
            .subscribe(onNext: { host in
                    print("\(host.peerDeviceDisplayName) connected")
                }
            )
            .disposed(by: disposeBag)

        incommingHostReconnectInvitations
            .subscribe(onNext: { handler in
                    handler(true)
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(
            forName: Notifications.didBecomeActive,
            object: nil,
            queue: nil,
            using: didBecomeActiveNotificationHandler
        )
    }
    
    private func store(host: DMEventPeer) {
        guard host.isHost else {
            return
        }
        
        let hostData = NSKeyedArchiver.archivedData(withRootObject: host)
        UserDefaults.standard.set(hostData, forKey: HostCacheKey)
    }
    
    func requestReconnect() -> Action<(DMEventPeer), Void> {
        return Action(workFactory: { (eventPeer: DMEventPeer) in
                return self.multipeerService.connect(eventPeer.peerID, context: MultipeerEventContexts.participantReconnect)
            }
        )
    }
    
}
