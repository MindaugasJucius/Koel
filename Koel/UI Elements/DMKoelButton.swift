//
//  KoelButton.swift
//  Koel
//
//  Created by Mindaugas Jucius on 11/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift

protocol KoelButtonColorable {
    var textColor: UIColor { get set }
    var backgroundColor: CGColor { get set }
    var shadowColor: CGColor { get set }

    init(themeType: ThemeType)
}

private struct KoelButtonColors: KoelButtonColorable {
    var textColor: UIColor
    var backgroundColor: CGColor
    var shadowColor: CGColor

    init(themeType: ThemeType) {
        let theme = themeType.theme
        self.textColor = .white
        self.backgroundColor = theme.primaryActionColor.cgColor
        self.shadowColor = theme.primaryActionColor.cgColor
    }
}

private struct KoelButtonDisabledColors: KoelButtonColorable {
    var textColor: UIColor
    var backgroundColor: CGColor
    var shadowColor: CGColor
    
    init(themeType: ThemeType) {
        let theme = themeType.theme
        self.textColor = .gray
        self.backgroundColor = theme.disabledColor.cgColor
        self.shadowColor = theme.disabledColor.cgColor
    }
}

protocol KoelButtonAppearance {
    var transform: CATransform3D { get }
    var shadowOffset: CGSize { get }
    var shadowOpacity: Float { get }
    var shadowRadius: CGFloat { get }
    var dimmingViewOpacity: Float { get }
    var colors: KoelButtonColorable { get set }
}

private struct KoelButtonDefaultAppearance: KoelButtonAppearance {
    
    let transform: CATransform3D
    let shadowOffset: CGSize
    let shadowOpacity: Float
    let shadowRadius: CGFloat
    let dimmingViewOpacity: Float
    var colors: KoelButtonColorable
    
    init(buttonColors: KoelButtonColorable) {
        transform = CATransform3DIdentity
        shadowOffset = CGSize(width: 0, height: 8)
        shadowOpacity = 0.4
        shadowRadius = 5
        colors = buttonColors
        dimmingViewOpacity = 0
    }
}

struct KoelButtonEndAppearance: KoelButtonAppearance {
    let transform: CATransform3D
    let shadowOffset: CGSize
    let shadowOpacity: Float
    let shadowRadius: CGFloat
    let dimmingViewOpacity: Float
    var colors: KoelButtonColorable
    
    init(buttonColors: KoelButtonColorable) {
        transform = CATransform3DMakeScale(0.98, 0.98, 1)
        shadowOffset = CGSize(width: 0, height: 6)
        shadowOpacity = 0.5
        shadowRadius = 3
        colors = buttonColors
        dimmingViewOpacity = 0.5
    }
}

private let AnimationDuration = 0.15
private let CornerRadius: CGFloat = 25
private let Insets = UIEdgeInsets(top: 0, left: 50, bottom: 25, right: 50)
private let Height: CGFloat = 50

class DMKoelButton: UIButton, Themeable {

    private let disposeBag = DisposeBag()
    
    let themeManager: ThemeManager
    
    private var currentAppearance: KoelButtonAppearance!
    
    private var startAppearance: KoelButtonAppearance!
    private var endAppearance: KoelButtonAppearance!
    private var disabledAppearance: KoelButtonAppearance!
    
    private lazy var dimmingView: UIView = { this in
        let view = UIView(frame: .zero)
        this.addSubview(view)
        view.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        view.layer.cornerRadius = CornerRadius
        view.isUserInteractionEnabled = false
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
    
    override var isEnabled: Bool {
        didSet {
            if !isEnabled {
                animate(toAppearanceState: disabledAppearance)
            } else {
                animate(toAppearanceState: startAppearance)
            }
        }
    }
    
    init(themeManager: ThemeManager) {
        self.themeManager = themeManager
        
        super.init(frame: .zero)
        
        //updateAppearances(forThemeType: currentTheme)
        initialConfiguration()
        bindThemeManager()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindThemeManager() {
        themeManager.currentTheme
            .do(onNext: { [unowned self] themeType in
                self.updateAppearances(forThemeType: themeType)
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func updateAppearances(forThemeType themeType: ThemeType) {
        let disabledColors = KoelButtonDisabledColors(themeType: themeType)
        let buttonColors = KoelButtonColors(themeType: themeType)
        
        let disabledAppearance = KoelButtonDefaultAppearance(buttonColors: disabledColors)
        let startAppearance = KoelButtonDefaultAppearance(buttonColors: buttonColors)
        let endAppearance = KoelButtonEndAppearance(buttonColors: buttonColors)
        
        if self.isEnabled {
            self.currentAppearance = startAppearance
        } else {
            self.currentAppearance = disabledAppearance
        }
        
        self.startAppearance = startAppearance
        self.endAppearance = endAppearance
        self.disabledAppearance = disabledAppearance
        
        configure(withAppearance: self.currentAppearance)
    }
    
    private func initialConfiguration() {
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        layer.cornerRadius = CornerRadius
        layer.masksToBounds = false

        addTarget(self, action: #selector(dragEnter), for: .touchDragEnter)
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        addTarget(self, action: #selector(dragExit), for: .touchDragExit)
    }
    
    @objc func touchUpInside() {
        animate(toAppearanceState: startAppearance)
    }
    
    @objc func dragExit() {
        animate(toAppearanceState: startAppearance)
    }
    
    @objc func touchDown() {
        animate(toAppearanceState: endAppearance)
    }
    
    @objc func dragEnter() {
        animate(toAppearanceState: endAppearance)
    }
    
    /// Edit model layer after animation
    private func configure(withAppearance appearance: KoelButtonAppearance) {
        layer.transform = appearance.transform
        layer.shadowRadius = appearance.shadowRadius
        layer.shadowOffset = appearance.shadowOffset
        layer.shadowOpacity = appearance.shadowOpacity
        layer.shadowColor = appearance.colors.shadowColor
        layer.backgroundColor = appearance.colors.backgroundColor
        setTitleColor(appearance.colors.textColor, for: .normal)
        dimmingView.layer.opacity = appearance.dimmingViewOpacity
    }
    
    func addConstraints(inSuperview superview: UIView) {
        let constraints = [
            leftAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leftAnchor, constant: Insets.left),
            superview.safeAreaLayoutGuide.rightAnchor.constraint(equalTo: rightAnchor, constant: Insets.right),
            superview.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Insets.bottom),
            heightAnchor.constraint(equalToConstant: Height)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    private func animate(toAppearanceState appearance: KoelButtonAppearance) {
        // Shadow transformations
        let shadowOffsetAnimation = CABasicAnimation(keyPath: "shadowOffset")
        
        shadowOffsetAnimation.fromValue = currentAppearance.shadowOffset
        shadowOffsetAnimation.toValue = appearance.shadowOffset
        
        let shadowOpacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        shadowOpacityAnimation.fromValue = currentAppearance.shadowOpacity
        shadowOpacityAnimation.toValue = appearance.shadowOpacity
        
        let shadowRadiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        shadowRadiusAnimation.fromValue = currentAppearance.shadowRadius
        shadowRadiusAnimation.toValue = appearance.shadowRadius
        
        let shadowColorAnimation = CABasicAnimation(keyPath: "shadowColor")
        shadowColorAnimation.fromValue = currentAppearance.colors.shadowColor
        shadowColorAnimation.toValue = appearance.colors.shadowColor
        
        let shadowGroup = CAAnimationGroup()
        shadowGroup.animations = [shadowOffsetAnimation,
                                  shadowOpacityAnimation,
                                  shadowRadiusAnimation,
                                  shadowColorAnimation]
        shadowGroup.duration = AnimationDuration

        // Button's view animations
        let backgroundColorAnimation = CABasicAnimation(keyPath: "backgroundColor")
        backgroundColorAnimation.fromValue = currentAppearance.colors.backgroundColor
        backgroundColorAnimation.toValue = appearance.colors.backgroundColor
        
        let transformAnimation = CABasicAnimation(keyPath: "transform")
        transformAnimation.fromValue = currentAppearance.transform
        transformAnimation.toValue = appearance.transform
        
        let group = CAAnimationGroup()
        group.animations = [transformAnimation, shadowGroup, backgroundColorAnimation]
        group.duration = AnimationDuration
        layer.add(group, forKey: nil)
        
        // Dimming view animations
        let dimmingViewOpacityAnimation = CABasicAnimation(keyPath: "opacity")
        dimmingViewOpacityAnimation.fromValue = currentAppearance.dimmingViewOpacity
        dimmingViewOpacityAnimation.toValue = appearance.dimmingViewOpacity
        
        dimmingView.layer.add(dimmingViewOpacityAnimation, forKey: nil)

        currentAppearance = appearance
        configure(withAppearance: appearance)
    }
    
}
