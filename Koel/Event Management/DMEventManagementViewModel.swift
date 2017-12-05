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

struct DMEventManagementViewModel {
    
    private let disposeBag = DisposeBag()
    
    private let multipeerService: DMEventMultipeerService
    private let host: DMEventPeer
    
    var hostExists: Observable<Bool> {
        return multipeerService.connectedPeers().map { peers in
            return peers.filter { $0.peerID == self.host.peerID }.count == 1
        }
    }
    
    private var incommingReconnectInvitations: Observable<(Bool) -> ()> {
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
    
    init(withMultipeerService multipeerService: DMEventMultipeerService, withHost host: DMEventPeer) {
        self.multipeerService = multipeerService
        self.host = host
        multipeerService.latestConnectedPeer()
            .subscribe(onNext: { host in
                    print("\(host.peerDeviceDisplayName) connected")
                }
            )
            .disposed(by: disposeBag)

        incommingReconnectInvitations
            .subscribe(onNext: { handler in
                    handler(true)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
