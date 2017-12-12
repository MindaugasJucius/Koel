//
//  KoelButton.swift
//  Koel
//
//  Created by Mindaugas Jucius on 11/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

let revolutPink = UIColor(red: 235/255, green: 2/255, blue: 141/255, alpha: 1)

protocol KoelButtonAppearance {
    var transform: CATransform3D { get }
    var shadowOffset: CGSize { get }
    var shadowOpacity: Float { get }
    var shadowRadius: CGFloat { get }
    var textColor: UIColor { get }
    var backgroundColor: UIColor { get }
    var dimmingViewOpacity: Float { get }
    var shadowColor: CGColor { get }
}

struct KoelButtonStartAppearance: KoelButtonAppearance {
    
    let transform: CATransform3D
    let shadowOffset: CGSize
    let shadowOpacity: Float
    let shadowRadius: CGFloat
    let backgroundColor: UIColor
    let textColor: UIColor
    let dimmingViewOpacity: Float
    let shadowColor: CGColor
    
    init() {
        transform = CATransform3DIdentity
        shadowOffset = CGSize(width: 0, height: 8)
        shadowOpacity = 0.4
        shadowRadius = 5
        backgroundColor = revolutPink
        textColor = .white
        dimmingViewOpacity = 0
        shadowColor = revolutPink.cgColor
    }
}

struct KoelButtonEndAppearance: KoelButtonAppearance {
    let transform: CATransform3D
    let shadowOffset: CGSize
    let shadowOpacity: Float
    let shadowRadius: CGFloat
    let backgroundColor: UIColor
    let textColor: UIColor
    let dimmingViewOpacity: Float
    let shadowColor: CGColor
    
    init() {
        transform = CATransform3DMakeScale(0.98, 0.98, 1)
        shadowOffset = CGSize(width: 0, height: 6)
        shadowOpacity = 0.5
        shadowRadius = 3
        backgroundColor = revolutPink
        textColor = UIColor.white.withAlphaComponent(0.3)
        dimmingViewOpacity = 0.5
        shadowColor = revolutPink.cgColor
    }
}

class KoelButton: UIButton {
    
    private var currentAppearance: KoelButtonAppearance
    
    private var startAppearance: KoelButtonAppearance
    private var endAppearance: KoelButtonAppearance
    
    private lazy var dimmingView: UIView = { this in
        let view = UIView(frame: .zero)
        this.addSubview(view)
        
        view.layer.cornerRadius = 50 / 2
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            view.leftAnchor.constraint(equalTo: this.leftAnchor),
            view.topAnchor.constraint(equalTo: this.topAnchor),
            this.rightAnchor.constraint(equalTo: view.rightAnchor),
            this.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]
        NSLayoutConstraint.activate(constraints)
        return view
    }(self)
    
    init(withInitialAppearance initialAppearance: KoelButtonAppearance = KoelButtonStartAppearance(),
         endAppearance: KoelButtonAppearance = KoelButtonEndAppearance()) {
        self.currentAppearance = initialAppearance
        self.startAppearance = initialAppearance
        self.endAppearance = endAppearance
        super.init(frame: .zero)
        
        initialConfiguration()
        configure(withAppearance: initialAppearance)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
    private func initialConfiguration() {
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 15)
        setTitle("ADD A SONG", for: .normal)
        setTitleColor(startAppearance.textColor, for: .normal)
        setTitleColor(endAppearance.textColor, for: .highlighted)
        
        layer.cornerRadius = 50 / 2
        layer.masksToBounds = false
        layer.shadowColor = currentAppearance.shadowColor
        
        addTarget(self, action: #selector(dragEnter), for: .touchDragEnter)
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        addTarget(self, action: #selector(dragExit), for: .touchDragExit)
    }
    
    @objc func touchUpInside() {
        animate(toState: startAppearance)
    }
    
    @objc func dragExit() {
        animate(toState: startAppearance)
    }
    
    @objc func touchDown() {
        animate(toState: endAppearance)
    }
    
    @objc func dragEnter() {
        animate(toState: endAppearance)
    }
    
    private func configure(withAppearance appearance: KoelButtonAppearance) {
        layer.transform = appearance.transform
        layer.shadowRadius = appearance.shadowRadius
        layer.shadowOffset = appearance.shadowOffset
        layer.shadowOpacity = appearance.shadowOpacity
        backgroundColor = appearance.backgroundColor
        dimmingView.layer.opacity = appearance.dimmingViewOpacity
    }
    
    func addConstraints(inSuperview superview: UIView) {
        let constraints = [
            leftAnchor.constraint(equalTo: superview.leftAnchor, constant: 50),
            superview.rightAnchor.constraint(equalTo: rightAnchor, constant: 50),
            superview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 25),
            heightAnchor.constraint(equalToConstant: 50)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    private func animate(toState appearance: KoelButtonAppearance) {
        let transformAnimation = CABasicAnimation(keyPath: "transform")
        transformAnimation.fromValue = currentAppearance.transform
        transformAnimation.toValue = appearance.transform
        
        let shadowOffsetAnimation = CABasicAnimation(keyPath: "shadowOffset")
        
        shadowOffsetAnimation.fromValue = currentAppearance.shadowOffset
        shadowOffsetAnimation.toValue = appearance.shadowOffset
        
        let shadowOpacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        shadowOpacityAnimation.fromValue = currentAppearance.shadowOpacity
        shadowOpacityAnimation.toValue = appearance.shadowOpacity
        
        let shadowRadiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        shadowRadiusAnimation.fromValue = currentAppearance.shadowRadius
        shadowRadiusAnimation.toValue = appearance.shadowRadius
        
        let dimmingViewOpacityAnimation = CABasicAnimation(keyPath: "opacity")
        dimmingViewOpacityAnimation.fromValue = currentAppearance.dimmingViewOpacity
        dimmingViewOpacityAnimation.toValue = appearance.dimmingViewOpacity
        
        let shadowGroup = CAAnimationGroup()
        shadowGroup.animations = [shadowOffsetAnimation, shadowOpacityAnimation, shadowRadiusAnimation]
        shadowGroup.duration = 0.2
        
        let group = CAAnimationGroup()
        group.animations = [transformAnimation, shadowGroup]
        group.duration = 0.2
        
        layer.add(group, forKey: nil)
        dimmingView.layer.add(dimmingViewOpacityAnimation, forKey: nil)
        
        currentAppearance = appearance
        configure(withAppearance: appearance)
    }
    
}
