//
//  DMSpotifySongTableViewCell.swift
//  Koel
//
//  Created by Mindaugas Jucius on 3/31/18.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit

class DMSpotifySongTableViewCell: UITableViewCell, ReusableView {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        imageView?.backgroundColor = .blue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(withSong song: DMSearchResultSong) {
        textLabel?.text = song.title
        detailTextLabel?.text = song.artistName
    }
}
