//
//  MultipeerModelType.swift
//  Koel
//
//  Created by Mindaugas Jucius on 07/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation

protocol MultipeerViewModelType {
    
    var multipeerService: DMEventMultipeerService { get }

}

extension MultipeerViewModelType {
    
    var selfPeer: DMEventPeer {
        return multipeerService.myEventPeer
    }
}
