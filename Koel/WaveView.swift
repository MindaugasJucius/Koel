/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SCSiriWaveformView
import UIKit

struct UIConstants {

    struct colors {
        static let focusLightBlue = UIColor(rgb: 0x00A7E0)
        static let focusDarkBlue = UIColor(rgb: 0x005DA5)
        static let focusBlue = UIColor(rgb: 0x00A7E0)
        static let focusGreen = UIColor(rgb: 0x7ED321)
        static let focusMaroon = UIColor(rgb: 0xE63D2F)
        static let focusOrange = UIColor(rgb: 0xF26C23)
        static let focusRed = UIColor(rgb: 0xE63D2F)
        static let focusViolet = UIColor(rgb: 0x95368C)
    }

}

private let ActiveInactiveTransitionStep: CGFloat = 0.05
private let ColorTransitionStep: Float = 0.002
private let PrimaryWaveActiveColors = [UIConstants.colors.focusOrange, UIConstants.colors.focusRed, UIConstants.colors.focusViolet, UIConstants.colors.focusLightBlue, UIConstants.colors.focusViolet, UIConstants.colors.focusRed]
private let PrimaryWaveColorCount = PrimaryWaveActiveColors.count
private let PrimaryWaveInactiveColor = UIColor.gray
private let SecondaryWaveColor = UIColor.gray
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
        //backWaveView.primaryWaveColor = PrimaryWaveInactiveColor
        backWaveView.secondaryWaveLineWidth = 0.5
        //backWaveView.secondaryWaveColor = UIColor.darkGray
        backWaveView.update(withLevel: 0)
        addSubview(backWaveView)

        frontWaveView.translatesAutoresizingMaskIntoConstraints = false
        frontWaveView.backgroundColor = UIColor.clear
        frontWaveView.phaseShift = -0.02
        frontWaveView.primaryWaveLineWidth = 2
        //frontWaveView.primaryWaveColor = PrimaryWaveInactiveColor
        frontWaveView.secondaryWaveLineWidth = 0.5
        //frontWaveView.secondaryWaveColor = SecondaryWaveColor
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
//        frontWaveView.snp.makeConstraints { make in
//            make.top.bottom.equalTo(self)
//            make.leading.trailing.equalTo(self).inset(-40)
//        }
//
//        backWaveView.snp.makeConstraints { make in
//            make.top.bottom.equalTo(self)
//            make.leading.trailing.equalTo(self).inset(-15)
//        }

        clipsToBounds = true

        let displayLink = CADisplayLink(target: self, selector: #selector(WaveView.displayLink(_:)))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func displayLink(_ sender: CADisplayLink) {
        colorLerp = (colorLerp + ColorTransitionStep).truncatingRemainder(dividingBy: Float(PrimaryWaveColorCount))
        let colorIndex = Int(colorLerp)
        let lerp = CGFloat(colorLerp - Float(colorIndex))
        let fromColor = PrimaryWaveActiveColors[colorIndex]
        let toColor = PrimaryWaveActiveColors[(colorIndex + 1) % PrimaryWaveColorCount]
//        let currentColor = fromColor.lerp(toColor: toColor, step: lerp)

        if active && waveLevel < WaveLevel {
            waveLevel += ActiveInactiveTransitionStep
            //frontWaveView.primaryWaveColor = PrimaryWaveInactiveColor.lerp(toColor: currentColor, step: waveLevel / WaveLevel)
        } else if !active && waveLevel > 0 {
            waveLevel -= ActiveInactiveTransitionStep
            //frontWaveView.primaryWaveColor = currentColor.lerp(toColor: PrimaryWaveInactiveColor, step: (WaveLevel - waveLevel) / WaveLevel)
        } else if active {
            //frontWaveView.primaryWaveColor = currentColor
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
