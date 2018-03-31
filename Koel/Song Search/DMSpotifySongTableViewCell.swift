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
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let labelStackView = UIStackView()
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.axis = .vertical
        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(artistTitleLabel)
        addSubview(labelStackView)
        
        let constraints = [labelStackView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
                           labelStackView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor),
                           labelStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                           labelStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(withSong song: DMEventSong) {
        titleLabel.text = song.title
        artistTitleLabel.text = song.artistTitle
    }
}
