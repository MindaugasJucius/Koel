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

struct DMEventParticipantViewModel: MultipeerViewModelType {
    
    private let disposeBag = DisposeBag()
    
    let multipeerService: DMEventMultipeerService
    let songSharingService: DMEventSongSharingServiceType
    
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
            print("hostNearby observable \(peers.map { $0.peerID?.displayName })")
            return peers.filter { $0.peerID == self.host.peerID }.count == 1
        }
    }
    
    private var incommingHostReconnectInvitations: Observable<(Bool) -> ()> {
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
                let reconnectContext = DMEventPeerPersistenceContexts.participantReconnect
                return this.multipeerService.connect(eventPeer.peerID, context: reconnectContext)
            }
        )
    }(self)
    
    init(withMultipeerService multipeerService: DMEventMultipeerService, withHost host: DMEventPeer) {
        self.multipeerService = multipeerService
        let songSharingService = DMEventSongSharingService()
        self.songSharingService = songSharingService
        self.host = host

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
        
        self.multipeerService.receive()
            .subscribe(
                onNext: { peerID, data in
                    do {
                        let song = try songSharingService.parseSong(fromData: data)
                        print("retrieved a song: \(song), added uuid: \(song.addedByUUID), upvoted uuids: \(song.upvotedByUUIDs)")
                    } catch let error {
                        print("song parsing failed: \(error.localizedDescription)")
                    }
                }
            )
            .disposed(by: disposeBag)
    
        NotificationCenter.default.addObserver(
            forName: Notifications.didEnterBackground,
            object: nil,
            queue: nil,
            using: didEnterBackgroundNotificationHandler
        )
    }
    
}
