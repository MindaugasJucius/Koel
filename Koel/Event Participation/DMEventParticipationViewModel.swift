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

protocol DMEventParticipationViewModelType: DMEventSongsRepresentable, DMEventParticipantSongsEditable {
    
    init(host: DMEventPeer,
         multipeerService: DMEventMultipeerService,
         songsSectionsRepresenter: DMEventSongsRepresentable,
         songsEditor: DMEventParticipantSongsEditable)
    
    var hostExists: Observable<Bool> { get }
    
}

class DMEventParticipationViewModel: DMEventParticipationViewModelType, MultipeerViewModelType, BackgroundDisconnectType {
    
    private let disposeBag = DisposeBag()
    private let host: DMEventPeer
    
    let multipeerService: DMEventMultipeerService
    
    let songsSectioned: Observable<[SongSection]>
    let onUpvote: (DMEventSong) -> (CocoaAction)
    
    var backgroundTaskID = UIBackgroundTaskInvalid

    var hostExists: Observable<Bool> {
        return multipeerService.connectedPeers()
            .map { [unowned self] peers in
                let hostExists = peers.filter { $0.peerID == self.host.peerID }.count == 1
                print("hostExists observable \(hostExists)")
                return hostExists
            }
    }
    
    private var hostNearby: Observable<Bool> {
        return multipeerService.nearbyFoundHostPeers()
            .map { [unowned self] peers in
                print("hostNearby observable \(peers.map { $0.peerID?.displayName })")
                return peers.filter { $0.peerID == self.host.peerID }.count == 1
            }
            .filter { $0 }
    }
    
    private var hostReconnectInvitations: Observable<(Bool) -> ()> {
        return multipeerService
            .incomingPeerInvitations()
            .filter { [unowned self] (client, context, handler) in
                let eventPeer = DMEventPeer.peer(withPeerID: client, context: context as? [String : String])
                return eventPeer.isHost && eventPeer.peerID == self.host.peerID
            }
            .map { (_, _, handler) in
                return handler
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
    
    required init(host: DMEventPeer,
                  multipeerService: DMEventMultipeerService,
                  songsSectionsRepresenter: DMEventSongsRepresentable,
                  songsEditor: DMEventParticipantSongsEditable) {
        
        self.host = host
        self.songsSectioned = songsSectionsRepresenter.songsSectioned
        self.onUpvote = songsEditor.onUpvote
        self.multipeerService = multipeerService
        
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
        
        NotificationCenter.default.addObserver(
            forName: Notifications.willEnterForeground,
            object: nil,
            queue: nil,
            using: willEnterForegroundNotificationHandler
        )
        
    }
    
}
