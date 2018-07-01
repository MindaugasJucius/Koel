//
//  DMSpotifySongTableViewCell.swift
//  Koel
//
//  Created by Mindaugas Jucius on 3/31/18.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift

class DMSpotifySongTableViewCell: UITableViewCell, ReusableView, Themeable {
    
    private var disposeBag = DisposeBag()
    
    var themeManager: ThemeManager = ThemeManager.shared
    
    private lazy var durationLabel: UILabel = {
        let durationLabel = UILabel(style: SongCellStylesheet.subtitleLabelStyle)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        return durationLabel
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        bindThemeManager()
        textLabel?.apply(SongCellStylesheet.titleLabelStyle)
        detailTextLabel?.apply(SongCellStylesheet.subtitleLabelStyle)

        selectedBackgroundView = UIView()
        contentView.addSubview(durationLabel)
        let constraints = [durationLabel.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
                           durationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)]
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        animate(toSelected: selected)
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
        super.prepareForReuse()
        bindThemeManager()
    }
    
    func configure(withSong song: DMSearchResultSong) {
        textLabel?.text = song.title
        detailTextLabel?.text = "\(song.artistName) • \(song.albumName)"
        durationLabel.text = String.secondsString(from: song.durationSeconds)
        imageView?.image = song.image
        imageView?.layer.cornerRadius = 5
    }
    
    func bindThemeManager() {
        themeManager.currentTheme
            .do(onNext: { [unowned self] themeType in
                self.backgroundColor = themeType.theme.backgroundColor
                self.textLabel?.textColor = themeType.theme.primaryTextColor
                self.detailTextLabel?.textColor = themeType.theme.secondaryTextColor
                self.durationLabel.textColor = themeType.theme.secondaryTextColor
                self.tintColor = themeType.theme.tintColor
                self.selectedBackgroundView?.backgroundColor = themeType.theme.selectedBackground
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func animate(toSelected selected: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.accessoryType = selected ? .checkmark : .none
            self.transform = selected ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
        }
    }
    
}
