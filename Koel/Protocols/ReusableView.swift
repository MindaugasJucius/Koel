//
//  ReusableViewType.swift
//  Koel
//
//  Created by Mindaugas on 12/03/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit

protocol ReusableView where Self: UIView {
    
    static var reuseIdentifier: String { get }
    
}

extension ReusableView {
    
    static var reuseIdentifier: String {
        return String(describing: self)
    }
    
}

protocol RepresentableReusableView: ReusableView where Self: UITableViewCell {
    associatedtype Representable: Representing
        
    func configure(withRepresentable representable: Representable)
    
}
