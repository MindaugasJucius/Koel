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

struct DMEventParticipationViewModel: MultipeerViewModelType {

    private let disposeBag = DisposeBag()
    
    let songSharingViewModel: DMEventSongSharingViewModelType
    
    private let host: DMEventPeer
    
    var multipeerService: DMEventMultipeerService {
        return songSharingViewModel.multipeerService
    }
    
    var hostExists: Observable<Bool> {
        return multipeerService.connectedPeers()
            .map { peers in
                let hostExists = peers.filter { $0.peerID == self.host.peerID }.count == 1
                print("hostExists observable \(hostExists)")
                return hostExists
            }
    }
    
    private var hostNearby: Observable<Bool> {
        return multipeerService.nearbyFoundHostPeers()
            .map { peers in
                print("hostNearby observable \(peers.map { $0.peerID?.displayName })")
                return peers.filter { $0.peerID == self.host.peerID }.count == 1
            }
            .filter { $0 }
    }
    
    private var hostReconnectInvitations: Observable<(Bool) -> ()> {
        return multipeerService
            .incomingPeerInvitations()
            .filter { (client, context, handler) in
                let eventPeer = DMEventPeer.peer(withPeerID: client, context: context as? [String : String])
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
                print("requesting reconnection for \(eventPeer.peerID?.displayName)")
                let reconnectContext = ContextKeys.reconnect.dictionary
                return this.multipeerService.connect(eventPeer.peerID, context: reconnectContext)
            }
        )
    }(self)
    
    init(host: DMEventPeer, songSharingViewModel: DMEventSongSharingViewModelType) {
        self.songSharingViewModel = songSharingViewModel
        self.host = host

        hostReconnectInvitations
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
            .withLatestFrom(hostDisconnectedObservable)
            .filter { $0 }
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
    
}
