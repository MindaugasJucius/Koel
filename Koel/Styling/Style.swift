//
//  Style.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

public struct Style<View: UIView> {
    
    let style: (View) -> Void
    
    init(_ style: @escaping (View) -> Void) {
        self.style = style
    }
    
    func apply(to view: View) {
        style(view)
    }
}

extension UIView {
    
    convenience init<V>(style: Style<V>) {
        self.init(frame: .zero)
        apply(style)
    }
    
    func apply<V>(_ style: Style<V>) {
        guard let view = self as? V else {
            print("Could not apply style for \(V.self) to \(type(of: self))")
            return
        }
        style.apply(to: view)
    }
}
