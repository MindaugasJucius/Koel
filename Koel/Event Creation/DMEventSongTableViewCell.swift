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

class DMEventSongTableViewCell: UITableViewCell {

    private var disposeBag = DisposeBag()
    
    func configure(withSong song: DMEventSong) {
        textLabel?.text = ""

        let playedObservable = song.rx.observe(Date.self, "played").startWith(nil)
        let addedObservable = song.rx.observe(Date.self, "added").startWith(song.added)
        let titleObservable = song.rx.observe(String.self, "title").startWith(song.title)

        Observable.combineLatest(
            playedObservable, addedObservable, titleObservable,
            resultSelector: { played, added, title in
                
                if let playedDate = played {
                    return "\(title!) played at \(playedDate)"
                } else {
                    return "\(title!) added at \(added!)"
                }
            }
        )
            .bind(to: textLabel!.rx.text)
            .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
        super.prepareForReuse()
    }
}
