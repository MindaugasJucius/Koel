//
//  DMEventSearchingViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 01/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Action
import RxSwift
import MultipeerConnectivity

class DMEventSearchViewModel: ViewModelType {
    
    private let disposeBag = DisposeBag()
    
    private let multipeerEventService = DMEventMultipeerService(withDisplayName: UIDevice.current.name, asEventHost: false)
    let sceneCoordinator: SceneCoordinatorType

    var eventHost = Variable<DMEventPeer?>(.none)
    
    var incommingInvitations: Observable<(DMEventPeer, (Bool) -> ())> {
        return multipeerEventService
            .incomingPeerInvitations()
            .map { (client, context, handler) in
                let eventPeer = DMEventPeer.init(withContext: context as? [String : String], peerID: client)
                return (eventPeer, handler)
            }
            .filter {
                $0.0.isHost
            }
    }
    
    var hosts: Observable<[DMEventPeer]> {
        return multipeerEventService.nearbyFoundHostPeers()
    }

    required init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
        multipeerEventService
            .latestConnectedPeer()
            .subscribe(onNext: { [unowned self] eventPeer in
                self.eventHost.value = eventPeer
                let managementModel = DMEventManagementViewModel(withMultipeerService: self.multipeerEventService)
                let managementScene = Scene.management(managementModel)
                self.sceneCoordinator.transition(to: managementScene, type: .push)
            }
        ).disposed(by: disposeBag)
    }
    
    func sendMessage() -> CocoaAction {
        return CocoaAction { [unowned self] in
            guard let host = self.eventHost.value else {
                return .just(())
            }
            let song = "message".data(using: .utf8)!
            return self.multipeerEventService.send(
                toPeer: host.peerID,
                data: song,
                mode: .reliable
            )
        }
    }
    
    func onStartAdvertising() {
        self.multipeerEventService.startAdvertising()
    }
    
    func onStartBrowsing() {
        self.multipeerEventService.startBrowsing()
    }
}
