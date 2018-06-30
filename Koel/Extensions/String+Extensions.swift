//
//  String+Extensions.swift
//  Koel
//
//  Created by Mindaugas on 01/07/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation

private let formatter = DateComponentsFormatter()

extension String {
    
    static func secondsString(from interval: TimeInterval) -> String? {
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: interval)
    }
    
}
