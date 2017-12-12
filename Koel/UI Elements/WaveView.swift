/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SCSiriWaveformView
import UIKit

private let ActiveInactiveTransitionStep: CGFloat = 0.05
private let WaveLevel: CGFloat = 0.8
private let PrimaryWaveFrequency: CGFloat = 1.2
private let SecondaryWaveFrequency: CGFloat = 0.8
private let BaseDeviceRatio: CGFloat = 1.875

class WaveView: UIView {
    var active = true

    fileprivate let frontWaveView = SCSiriWaveformView()
    fileprivate let backWaveView = SCSiriWaveformView()
    fileprivate var waveLevel: CGFloat = 0
    fileprivate var colorLerp: Float = 0

    init() {
        super.init(frame: CGRect.zero)

        backWaveView.translatesAutoresizingMaskIntoConstraints = false
        backWaveView.backgroundColor = UIColor.clear
        backWaveView.phaseShift = -0.022
        backWaveView.primaryWaveLineWidth = 1
        backWaveView.secondaryWaveLineWidth = 0.5
        backWaveView.update(withLevel: 0)
        addSubview(backWaveView)

        frontWaveView.translatesAutoresizingMaskIntoConstraints = false
        frontWaveView.backgroundColor = UIColor.clear
        frontWaveView.phaseShift = -0.02
        frontWaveView.primaryWaveLineWidth = 2
        frontWaveView.secondaryWaveLineWidth = 0.5
        frontWaveView.update(withLevel: 0)
        addSubview(frontWaveView)

        let constraints = [
                           frontWaveView.topAnchor.constraint(equalTo: topAnchor),
                           frontWaveView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -40),
                           frontWaveView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 40),
                           frontWaveView.bottomAnchor.constraint(equalTo: bottomAnchor),
                           
                           backWaveView.topAnchor.constraint(equalTo: topAnchor),
                           backWaveView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -15),
                           backWaveView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 15),
                           backWaveView.bottomAnchor.constraint(equalTo: bottomAnchor)
                          ]
        NSLayoutConstraint.activate(constraints)


        clipsToBounds = true

        let displayLink = CADisplayLink(target: self, selector: #selector(WaveView.displayLink(_:)))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func displayLink(_ sender: CADisplayLink) {
        if active && waveLevel < WaveLevel {
            waveLevel += ActiveInactiveTransitionStep

        } else if !active && waveLevel > 0 {
            waveLevel -= ActiveInactiveTransitionStep
        }
        
        backWaveView.update(withLevel: waveLevel - 0.1)
        frontWaveView.update(withLevel: waveLevel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let freqMultiplier: CGFloat = bounds.width / bounds.height / BaseDeviceRatio
        frontWaveView.frequency = PrimaryWaveFrequency * freqMultiplier
        backWaveView.frequency = SecondaryWaveFrequency * freqMultiplier
    }
}
