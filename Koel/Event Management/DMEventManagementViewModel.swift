//
//  DMEventManagementViewModel.swift
//  Koel
//
//  Created by Mindaugas Jucius on 04/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import Foundation

struct DMEventManagementViewModel {
    
    let multipeerService: DMEventMultipeerService
    
    init(withMultipeerService multipeerService: DMEventMultipeerService) {
        self.multipeerService = multipeerService
        print(self.multipeerService)
    }
    
}
