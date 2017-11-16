//
//  DMKoelLogoView.swift
//  Koel
//
//  Created by Mindaugas Jucius on 11/14/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

private let SinusWaveMaxHeight: CGFloat = 200
private let PrimaryKoelBlue = UIColor.colorWithHexString(hex: "19B5FE")

private let FirstScaleLayerColor = PrimaryKoelBlue.withAlphaComponent(0.4).cgColor
private let SecondScaleLayerColor = PrimaryKoelBlue.withAlphaComponent(0.6).cgColor

private let GradientStartColor = UIColor.colorWithHexString(hex: "#00dbde").cgColor
private let GradientEndColor = UIColor.colorWithHexString(hex: "#fc00ff").cgColor

class DMKoelLogoView: UIView {

    static let Height: CGFloat = SinusWaveMaxHeight + 25
    
    let waveView = WaveView()
    
    let waveContainerView = UIView()
    
    let firstScaleLayerContainer: CALayer = {
        let ovalLayer = CALayer()
        ovalLayer.backgroundColor = FirstScaleLayerColor
        return ovalLayer
    }()
    
    let secondScaleLayerContainer: CALayer = {
        let ovalLayer = CALayer()
        ovalLayer.backgroundColor = SecondScaleLayerColor
        return ovalLayer
    }()
    
    let gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [GradientStartColor, GradientEndColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        return gradientLayer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let oval = UIBezierPath(ovalIn: bounds)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = oval.cgPath
        waveContainerView.layer.mask = shapeLayer
        
        gradientLayer.frame = bounds
        firstScaleLayerContainer.frame = bounds
        secondScaleLayerContainer.frame = bounds
    }

    func startAnimating() {
        firstScaleLayerContainer.add(scaleAnimation(withTimeOffset: 0.4, maxScaleValue: 1.3), forKey: nil)
        secondScaleLayerContainer.add(scaleAnimation(maxScaleValue: 1.6), forKey: nil)
    }
    
    private func setupLayout() {
        translatesAutoresizingMaskIntoConstraints = false
        
        waveContainerView.translatesAutoresizingMaskIntoConstraints = false
        waveContainerView.layer.addSublayer(gradientLayer)
        addSubview(waveContainerView)
        
        let waveContainerViewConstraints = [
            waveContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            waveContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            waveContainerView.topAnchor.constraint(equalTo: topAnchor),
            waveContainerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(waveContainerViewConstraints)
        
        waveView.translatesAutoresizingMaskIntoConstraints = false
        waveContainerView.addSubview(waveView)
        
        let waveViewConstraints = [
            waveView.leadingAnchor.constraint(equalTo: leadingAnchor),
            waveView.trailingAnchor.constraint(equalTo: trailingAnchor),
            waveView.centerXAnchor.constraint(equalTo: centerXAnchor),
            waveView.centerYAnchor.constraint(equalTo: centerYAnchor),
            waveView.heightAnchor.constraint(equalToConstant: SinusWaveMaxHeight)
        ]
        
        NSLayoutConstraint.activate(waveViewConstraints)
        
        firstScaleLayerContainer.mask = scaleOval()
        layer.insertSublayer(firstScaleLayerContainer, below: waveContainerView.layer)
        
        secondScaleLayerContainer.mask = scaleOval()
        layer.insertSublayer(secondScaleLayerContainer, below: firstScaleLayerContainer)
    }
    
    private func scaleAnimation(withTimeOffset timeOffset: TimeInterval = 0, maxScaleValue: CGFloat = 1) -> CAAnimation {
        let animationGroup = CAAnimationGroup()

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = maxScaleValue
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1
        opacityAnimation.toValue = 0

        animationGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        animationGroup.duration = 4
        animationGroup.fillMode = kCAFillModeForwards
        animationGroup.repeatCount = .infinity
        animationGroup.beginTime = CACurrentMediaTime() + timeOffset

        return animationGroup
    }
    
    private func scaleOval() -> CAShapeLayer {
        let scaleOval = CAShapeLayer()
        let size = CGSize(width: DMKoelLogoView.Height, height: DMKoelLogoView.Height)
        let ovalBoundingRectangle = CGRect(origin: CGPoint.zero, size: size)
        scaleOval.path = UIBezierPath(ovalIn: ovalBoundingRectangle).cgPath
        return scaleOval
    }
    
}
