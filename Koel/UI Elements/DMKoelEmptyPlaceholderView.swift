//
//  DMKoelEmptyPlaceholderView.swift
//  Koel
//
//  Created by Mindaugas Jucius on 6/17/18.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit

class DMKoelEmptyPlaceholderTableViewCell: UITableViewCell, ReusableView {
    
    private let placeholderView = DMKoelEmptyPlaceholderView(frame: .zero)
    
    var placeholderImage: UIImage? {
        get {
            return placeholderView.placeholderImage
        }
        set {
            placeholderView.placeholderImage = newValue
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(placeholderView)
        let placeholderViewConstraints = [placeholderView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                                          placeholderView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                                          placeholderView.topAnchor.constraint(equalTo: contentView.topAnchor),
                                          placeholderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)]
        NSLayoutConstraint.activate(placeholderViewConstraints)
    }
}

class DMKoelEmptyPlaceholderView: UIView {

    private let label: UILabel = {
        let label = UILabel(style: SongCellStylesheet.titleLabelStyle)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray
        label.text = UIConstants.strings.noSearchResults
        return label
    }()
    
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView(image: nil)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var placeholderImage: UIImage? {
        get {
            return placeholderImageView.image
        }
        set {
            placeholderImageView.image = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        heightAnchor.constraint(equalToConstant: 500).isActive = true
        
        addSubview(placeholderImageView)

        let imageViewConstraints = [placeholderImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                                    placeholderImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                                    placeholderImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),
                                    placeholderImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5)]
        NSLayoutConstraint.activate(imageViewConstraints)
        
        addSubview(label)
        
        let labelConstraints = [label.centerXAnchor.constraint(equalTo: centerXAnchor),
                                label.topAnchor.constraint(equalTo: placeholderImageView.bottomAnchor)]
        NSLayoutConstraint.activate(labelConstraints)
        
    }

}
