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
    private let multipeerEventService = DMEventMultipeerService(
        withDisplayName: UIDevice.current.name,
        asEventHost: false
    )
    
    let sceneCoordinator: SceneCoordinatorType

    private var eventHost = Variable<DMEventPeer?>(.none)

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
    
    var host: Observable<DMEventPeer> {
        return multipeerEventService.latestConnectedPeer().share()
    }
    
    private lazy var pushManagement: Action<Void, Void> = {
        return Action(
            workFactory: { [unowned self] in
                let managementModel = DMEventManagementViewModel(withMultipeerService: self.multipeerEventService)
                let managementScene = Scene.management(managementModel)
                return self.sceneCoordinator.transition(to: managementScene, type: .push)
            }
        )
    }()
    
    lazy var requestAccess: Action<(DMEventPeer), Void> = { this in
        return Action(
            workFactory: { (eventPeer: DMEventPeer) in
                return this.multipeerEventService.connect(eventPeer.peerID, context: nil)
            }
        )
    }(self)

    required init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
        
        host
            .subscribe(onNext: { [unowned self] eventPeer in
                self.eventHost.value = eventPeer
            })
            .disposed(by: disposeBag)
        
        host
            .map { _ in }
            .observeOn(MainScheduler.instance)
            .subscribe(pushManagement.inputs)
            .disposed(by: disposeBag)
    }
    
    func onStartAdvertising() {
        self.multipeerEventService.startAdvertising()
    }
    
    func onStartBrowsing() {
        self.multipeerEventService.startBrowsing()
    }
}
