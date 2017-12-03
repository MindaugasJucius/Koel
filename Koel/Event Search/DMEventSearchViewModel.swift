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

struct DMEventSearchViewModel {
    
    private let multipeerEventService = DMEventMultipeerService(withDisplayName: UIDevice.current.name)
    private let sceneCoordinator: SceneCoordinatorType
    
    var incommingInvitations: Observable<(DMEventPeer, (Bool) -> ())> {
        return multipeerEventService.incomingPeerInvitations().map({ (client, context, handler) in
            let eventPeer = DMEventPeer.init(withContext: context as? [String : String], peerID: client)
            return (eventPeer, handler)
        })
    }
    
    var latestConnectedPeer: Observable<DMEventPeer> {
        return multipeerEventService.latestConnectedPeer().do(onNext: { eventHost in
            
        })
    }

    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
    }
    
    func onStartAdvertising() -> CocoaAction {
        return CocoaAction(
            workFactory: {
                return self.multipeerEventService.startAdvertising()
            }
        )
    }
    
}
