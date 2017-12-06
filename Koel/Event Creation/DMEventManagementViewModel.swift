//
//  DMEventManagementController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 06/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import Action
import RxSwift

struct DMEventManagementViewModel: ViewModelType {
    
    private let disposeBag = DisposeBag()
    
    let sceneCoordinator: SceneCoordinatorType
    private let multipeerService: DMEventMultipeerService
    private let peers = BehaviorSubject<[EventPeerSection]>(value: [EventPeerSection(model: "", items: [])])
    
    private var incommingInvitations: Observable<(DMEventPeer, (Bool) -> (), Bool)> {
        return multipeerService
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
    
    private var allPeersSectioned: Observable<[EventPeerSection]> {
        return Observable
            .of(multipeerService.nearbyFoundPeers(),
                multipeerService.connectedPeers())
            .merge()
            .map { results in
                
                let connectedPeers = results.filter { $0.isConnected }
                let nearbyPeers = results.filter { !$0.isConnected }
                
                print(results.map { return "CONNECTION OBSERVABLES RESULTS \($0.peerDeviceDisplayName) \($0.isConnected)" })
                
                return [
                    EventPeerSection(model: "Joined", items: connectedPeers),
                    EventPeerSection(model: "Nearby", items: nearbyPeers)
                ]
            }
            .observeOn(MainScheduler.instance)
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
    
    init(withSceneCoordinator sceneCoordinator: SceneCoordinatorType) {
        self.sceneCoordinator = sceneCoordinator
        self.multipeerService = DMEventMultipeerService(
            withDisplayName: UIDevice.current.name,
            asEventHost: true
        )
        
        multipeerService.startBrowsing()
        multipeerService.startAdvertising()
        
        incommingParticipantInvitations
            .subscribe(onNext: { invitation in
                let alert = UIAlertController(title: "Connection request", message: "\(invitation.0.peerDeviceDisplayName) wants to join your party", preferredStyle: .alert)
                let connectAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
                    let invitationHandler = invitation.1
                    invitationHandler(true)
                })
                alert.addAction(connectAction)
                sceneCoordinator.currentViewController.present(
                    alert,
                    animated: true,
                    completion: nil
                )
            })
            .disposed(by: disposeBag)
        
//        viewModel.latestConnectedPeer
//            .subscribe(onNext: { [unowned self] eventPeer in
//                let alert = UIAlertController(title: "New connection", message: "connected to \(eventPeer.peerDeviceDisplayName)", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//            })
//            .disposed(by: bag)
        
        allPeersSectioned
            .subscribe(peers.asObserver())
            .disposed(by: disposeBag)
        
        incommingParticipantReconnectInvitations
            .subscribe(onNext: { handler in
                handler(true)
            })
            .disposed(by: disposeBag)
    }
    
    private func onInvitesClose() -> CocoaAction {
        return CocoaAction {
            return self.sceneCoordinator.pop(animated: true)
        }
    }
    
    func onInvite() -> CocoaAction {
        return CocoaAction { _ in
            let invitationsViewModel = DMEventInvitationsViewModel(
                withSceneCoordinator: self.sceneCoordinator,
                multipeerService: self.multipeerService,
                peers: self.peers,
                onClose: self.onInvitesClose()
            )

            return self.sceneCoordinator.transition(
                to: Scene.invite(invitationsViewModel),
                type: .modal
            )
        }
    }
}
