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
        label.text = "empty"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        backgroundColor = .lightGray
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        let labelConstraints = [label.centerXAnchor.constraint(equalTo: centerXAnchor),
                                label.centerYAnchor.constraint(equalTo: centerYAnchor)]
        NSLayoutConstraint.activate(labelConstraints)
        heightAnchor.constraint(equalToConstant: 500).isActive = true
    }

}
