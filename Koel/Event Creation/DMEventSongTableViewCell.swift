//
//  DMEventSongTableViewCell.swift
//  Koel
//
//  Created by Mindaugas Jucius on 08/12/2017.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxOptional
import RealmSwift
import Action

class DMEventSongTableViewCell: UITableViewCell {

    private var disposeBag = DisposeBag()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var upvoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(titleLabel)
        let labelConstraints = [
            titleLabel.leftAnchor.constraintEqualToSystemSpacingAfter(contentView.leftAnchor, multiplier: 0),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            contentView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15)
        ]
        
        NSLayoutConstraint.activate(labelConstraints)
        
        contentView.addSubview(upvoteButton)
        let buttonConstraints = [
            contentView.rightAnchor.constraint(equalTo: upvoteButton.rightAnchor, constant: 5),
            upvoteButton.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 5),
            upvoteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ]
        
        NSLayoutConstraint.activate(buttonConstraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(withSong song: DMEventSong, upvoteAction: CocoaAction) {
        let playedObservable = song.rx.observe(Date.self, "played")
            .share(replay: 1, scope: SubjectLifetimeScope.whileConnected)
        
        let addedObservable = song.rx.observe(Date.self, "added")
            .startWith(song.added)
            .filterNil()
        
        let titleObservable = song.rx.observe(String.self, "title")
            .startWith(song.title)
            .filterNil()

        Observable.combineLatest(
            playedObservable, addedObservable, titleObservable,
            resultSelector: { played, added, title in
                    if let playedDate = played {
                        return "\(title) played at \(playedDate)"
                    } else {
                        return "\(title) added at \(added)"
                    }
                }
            )
            .bind(to: titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        upvoteButton.rx.action = upvoteAction
        
        let playedUpvoteCountEnabled = playedObservable
            .filterNil()
            .map { _ in false }

        let tappedUpvoteCountEnabled = upvoteButton.rx.controlEvent(.touchUpInside)
            .asObservable()
            .map { false }

        playedUpvoteCountEnabled.amb(tappedUpvoteCountEnabled)
        .bind(to: upvoteButton.rx.isEnabled)
        .disposed(by: disposeBag)
        
        song.rx.observe(Int.self, "upvoteCount")
            .filterNil()
            .map { String($0) }
            .bind(to: upvoteButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        upvoteButton.rx.action = nil
        disposeBag = DisposeBag()
        super.prepareForReuse()
    }
}
