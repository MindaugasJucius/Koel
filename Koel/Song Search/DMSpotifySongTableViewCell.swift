//
//  DMSpotifySongTableViewCell.swift
//  Koel
//
//  Created by Mindaugas Jucius on 3/31/18.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit

class DMSpotifySongTableViewCell: UITableViewCell, ReusableView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.apply(SongCellStylesheet.titleLabelStyle)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var artistTitleLabel: UILabel = {
        let label = UILabel()
        label.apply(SongCellStylesheet.subtitleLabelStyle)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let labelStackView = UIStackView()
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.axis = .vertical
        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(artistTitleLabel)
        labelStackView.spacing = 3
        return labelStackView
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(stackView)
        
        let constraints = [stackView.leftAnchor.constraintEqualToSystemSpacingAfter(safeAreaLayoutGuide.leftAnchor, multiplier: 2),
                           safeAreaLayoutGuide.rightAnchor.constraintEqualToSystemSpacingAfter(stackView.rightAnchor, multiplier: 1),
                           stackView.topAnchor.constraintEqualToSystemSpacingBelow(safeAreaLayoutGuide.topAnchor, multiplier: 1),
                           safeAreaLayoutGuide.bottomAnchor.constraintEqualToSystemSpacingBelow(stackView.bottomAnchor, multiplier: 1)
                          ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(withSong song: DMSearchResultSong) {
        titleLabel.text = song.title
        artistTitleLabel.text = song.artistName
    }
}
