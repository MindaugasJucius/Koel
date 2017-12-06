//
//  DMEventInvitationsViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 30/11/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import MultipeerConnectivity
import RxSwift
import Action

struct DMEventInvitationsViewModel: ViewModelType {

    private let disposeBag = DisposeBag()
    
    private let multipeerEventService = DMEventMultipeerService(withDisplayName: UIDevice.current.name, asEventHost: true)
    let sceneCoordinator: SceneCoordinatorType
    
    var allPeersSectioned: Observable<[EventPeerSection]> {
        return Observable
            .of(multipeerEventService.nearbyFoundPeers(),
                multipeerEventService.connectedPeers())
            .merge()
            .map { results in

                let connectedPeers = results.filter { $0.isConnected }
                let notConnectedPeers = results.filter { !$0.isConnected }
                
                return [
                    EventPeerSection(model: "Joined", items: connectedPeers),
                    EventPeerSection(model: "Nearby", items: notConnectedPeers)
                ]
            }
            .observeOn(MainScheduler.instance)
    }
    
    var latestConnectedPeer: Observable<DMEventPeer> {
        return multipeerEventService.latestConnectedPeer()
    }
    
    //MARK: - Actions

    private var incommingInvitations: Observable<(DMEventPeer, (Bool) -> (), Bool)> {
        return multipeerEventService
            .incomingPeerInvitations()
            .map { (client, context, handler) in

                guard let contextDictionary = context else {
                    return (DMEventPeer.init(withContext: nil, peerID: client), handler, false)
                }

                let isReconnect = contextDictionary[MultipeerEventContexts.ContextKeys.reconnect.rawValue] != nil
                let eventPeer = DMEventPeer.init(withContext: contextDictionary as? [String : String], peerID: client)
                
                return (eventPeer, handler, isReconnect)
            }
            .share()
    }
    
    var incommingParticipantInvitations: Observable<(DMEventPeer, (Bool) -> ())> {
        return incommingInvitations
            .filter{ (_, _, reconnect) in
                return !reconnect
            }
            .map { (client, handler, _) in
                return (client, handler)
            }
    }
    
    private var incommingParticipantReconnectInvitations: Observable<(Bool) -> ()> {
        return incommingInvitations
            .filter{ (_, _, reconnect) in
                return reconnect
            }
            .map { (_, handler, _) in
                return handler
            }
    }
    
    lazy var inviteAction: Action<(DMEventPeer), Void> = { this in
        return Action(
            workFactory: { (eventPeer: DMEventPeer) in
                let hostContext = MultipeerEventContexts.hostDiscovery
                return this.multipeerEventService.connect(eventPeer.peerID, context: hostContext)
            }
        )
    }(self)
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
        incommingParticipantReconnectInvitations.subscribe(onNext: { handler in
                handler(true)
            }
        ).disposed(by: disposeBag)
    }
    
    func onStartAdvertising(){
        self.multipeerEventService.startAdvertising()
    }

    func onStartBrowsing() {
        self.multipeerEventService.startBrowsing()
    }
    
}
