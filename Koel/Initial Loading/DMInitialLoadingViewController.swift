//
//  DMInitialLoadingViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/19/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift

private let SinusWaveMaxHeight: CGFloat = 200
private let SinusWaveContainerSideLength: CGFloat = SinusWaveMaxHeight + 75

class DMInitialLoadingViewController: UIViewController {

    let viewModel: DMInitialLoadingViewModelType
    
    let waveView = WaveView()
    let waveContainerView = UIView()
    
    let bag = DisposeBag()
    
    let firstScaleLayerContainer: CALayer = {
        let ovalLayer = CALayer()
        ovalLayer.backgroundColor = UIColor.black.withAlphaComponent(0.7).cgColor
        return ovalLayer
    }()
    
    let secondScaleLayerContainer: CALayer = {
        let ovalLayer = CALayer()
        ovalLayer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
        return ovalLayer
    }()
    
    init(withViewModelOfType viewModel: DMInitialLoadingViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let subscription = viewModel.userObservable?.subscribe(
            { user in
                
            }
        ).disposed(by: bag)

        waveContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(waveContainerView)
        waveContainerView.backgroundColor = .lightGray
        
        waveView.translatesAutoresizingMaskIntoConstraints = false
        waveContainerView.addSubview(waveView)

        firstScaleLayerContainer.mask = scaleOval()
        view.layer.insertSublayer(firstScaleLayerContainer, below: waveContainerView.layer)
        
        secondScaleLayerContainer.mask = scaleOval()
        view.layer.insertSublayer(secondScaleLayerContainer, below: firstScaleLayerContainer)
        
        let constraints = [
            waveContainerView.heightAnchor.constraint(equalToConstant: SinusWaveContainerSideLength),
            waveContainerView.widthAnchor.constraint(equalToConstant: SinusWaveContainerSideLength),
            waveContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            waveContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            waveView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            waveView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            waveView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            waveView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            waveView.heightAnchor.constraint(equalToConstant: SinusWaveMaxHeight)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    override func viewDidLayoutSubviews() {
        let oval = UIBezierPath(ovalIn: waveContainerView.bounds)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = oval.cgPath
        waveContainerView.layer.mask = shapeLayer
        
        firstScaleLayerContainer.frame = waveContainerView.frame
        firstScaleLayerContainer.add(scaleAnimation(withTimeOffset: 0.1, maxScaleValue: 1.2), forKey: nil)
    
        secondScaleLayerContainer.frame = waveContainerView.frame
        secondScaleLayerContainer.add(scaleAnimation(maxScaleValue: 1.3), forKey: nil)
    }
    
    func scaleAnimation(withTimeOffset timeOffset: TimeInterval = 0, maxScaleValue: CGFloat = 1) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.duration = 3
        anim.fromValue = 1
        anim.toValue = maxScaleValue
        anim.fillMode = kCAFillModeForwards
        anim.beginTime = CACurrentMediaTime() + timeOffset
        anim.repeatCount = .infinity
        return anim
    }
    
    func scaleOval() -> CAShapeLayer {
        let scaleOval = CAShapeLayer()
        let size = CGSize(width: SinusWaveContainerSideLength, height: SinusWaveContainerSideLength)
        let ovalBoundingRectangle = CGRect(origin: CGPoint.zero, size: size)
        scaleOval.path = UIBezierPath(ovalIn: ovalBoundingRectangle).cgPath
        return scaleOval
    }
    
}
