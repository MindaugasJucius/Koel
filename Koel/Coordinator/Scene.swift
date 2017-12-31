//
//  Scene.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

enum Scene {
    //MARK: Shared
    case selectFlow(DMFlowSelectionViewModel)

    //MARK: Host
    case invite(DMEventInvitationsViewModel)
    case manage(DMEventManagementViewModel)

    //MARK: Participant
    case search(DMEventSearchViewModel)
    case participation(DMEventParticipationViewModel)
    
    //MARK: Spotify
    case authenticateSpotify(URL)
}

extension Scene {
    func viewController() -> UIViewController {
        switch self {
        //MARK: General
        case .selectFlow(let viewModel):
            let flowSelectionVC = DMFlowSelectionViewController(withViewModel: viewModel)
            flowSelectionVC.setupForViewModel()
            return flowSelectionVC
        
        //MARK: Participant
        case .search(let viewModel):
            let eventSearchVC = DMEventSearchViewController(withViewModel: viewModel)
            eventSearchVC.setupForViewModel()
            return eventSearchVC
        case .participation(let viewModel):
            let eventParticipationVC = DMEventParticipationViewController(withViewModel: viewModel)
            eventParticipationVC.setupForViewModel()
            return eventParticipationVC
            
        //MARK: Host
        case .invite(let viewModel):
            let eventCreationVC = DMEventInvitationsViewController(withViewModel: viewModel)
            eventCreationVC.setupForViewModel()
            return eventCreationVC
        case .manage(let viewModel):
            let managementVC = DMEventManagementViewController(withViewModel: viewModel)
            managementVC.setupForViewModel()
            return managementVC
            
        //MARK: Spotify
        case .authenticateSpotify(let authenticationURL):
            let authenticationController = SFSafariViewController(url: authenticationURL)
            return authenticationController
        }
    }
}
