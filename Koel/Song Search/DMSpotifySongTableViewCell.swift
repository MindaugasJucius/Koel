//
//  DMSpotifySongTableViewCell.swift
//  Koel
//
//  Created by Mindaugas Jucius on 3/31/18.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift

private let cellHeight: CGFloat = 55

class DMSpotifySongTableViewCell: UITableViewCell, ReusableView, Themeable {
    
    private var disposeBag = DisposeBag()
    
    var themeManager: ThemeManager = ThemeManager.shared
    
    private var hasSetConstraints = false

    private lazy var albumArtImageView: UIImageView = {
        let imageView = UIImageView(image: nil)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var durationLabel: UILabel = {
        let durationLabel = UILabel(style: SongCellStylesheet.subtitleLabelStyle)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        return durationLabel
    }()

    private lazy var trackTitleLabel: UILabel = {
        let label = UILabel(style: SongCellStylesheet.titleLabelStyle)
        return label
    }()
    
    private lazy var albumAndArtistTitleLabel: UILabel = {
        let label = UILabel(style: SongCellStylesheet.subtitleLabelStyle)
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [trackTitleLabel, albumAndArtistTitleLabel])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        bindThemeManager()

        selectedBackgroundView = UIView()
        contentView.addSubview(durationLabel)
        contentView.addSubview(albumArtImageView)
        contentView.addSubview(stackView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        guard !hasSetConstraints else {
            super.updateConstraints()
            return
        }
        
        hasSetConstraints = true
        
        let areaGuide = contentView.safeAreaLayoutGuide

        let durationLabelConstraints = [
            durationLabel.trailingAnchor.constraint(equalTo: areaGuide.trailingAnchor),
            durationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ]
        
        NSLayoutConstraint.activate(durationLabelConstraints)
        
        let albumArtImageViewConstraints = [
            albumArtImageView.leadingAnchor.constraintEqualToSystemSpacingAfter(areaGuide.leadingAnchor, multiplier: 1),
            albumArtImageView.centerYAnchor.constraint(equalTo: areaGuide.centerYAnchor),
            albumArtImageView.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 1),
            albumArtImageView.widthAnchor.constraint(equalTo: albumArtImageView.heightAnchor, multiplier: 1)
        ]
        
        NSLayoutConstraint.activate(albumArtImageViewConstraints)
        
        let stackViewConstraints = [
            stackView.leadingAnchor.constraintEqualToSystemSpacingAfter(albumArtImageView.trailingAnchor, multiplier: 2),
            durationLabel.leadingAnchor.constraintGreaterThanOrEqualToSystemSpacingAfter(stackView.trailingAnchor, multiplier: 2),
            stackView.topAnchor.constraintEqualToSystemSpacingBelow(areaGuide.topAnchor, multiplier: 1),
            areaGuide.bottomAnchor.constraintEqualToSystemSpacingBelow(stackView.bottomAnchor, multiplier: 1),
            stackView.heightAnchor.constraint(equalToConstant: cellHeight)
        ]
        
        NSLayoutConstraint.activate(stackViewConstraints)
        
        super.updateConstraints()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        animate(toSelected: selected)
    }
    
    override func prepareForReuse() {
        albumArtImageView.image = nil
        disposeBag = DisposeBag()
        super.prepareForReuse()
        bindThemeManager()
    }
    
    func configure(withSong song: DMSearchResultSong) {
        trackTitleLabel.text = song.title
        albumAndArtistTitleLabel.text = "\(song.artistName) • \(song.albumName)"
        durationLabel.text = String.secondsString(from: song.durationSeconds)
        albumArtImageView.image = #imageLiteral(resourceName: "song cell placeholder")
        
        Observable.of(song)
            .downloadImage()
            .observeOn(MainScheduler.instance)
            .do(onNext: { songWithImage in
                self.albumArtImageView.image = songWithImage.image
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        setNeedsUpdateConstraints()
    }
    
    func bindThemeManager() {
        themeManager.currentTheme
            .do(onNext: { [unowned self] themeType in
                self.backgroundColor = themeType.theme.backgroundColor
                self.trackTitleLabel.textColor = themeType.theme.primaryTextColor
                self.albumAndArtistTitleLabel.textColor = themeType.theme.secondaryTextColor
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
