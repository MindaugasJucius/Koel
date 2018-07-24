//
//  ResultViewModel.swift
//  Koel
//
//  Created by Mindaugas on 23/07/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxCocoa

private class _AnyResultsViewModelBase<Model>: DMSpotifySongSearchViewModelType where Model: Representing {

    init() {
        guard type(of: self) != _AnyResultsViewModelBase.self else {
            fatalError("_AnyRowBase<Model> instances can not be created; create a subclass instance instead")
        }
    }
    
    var songResults: Driver<[SongSearchResultSectionModel<Model>]> {
        fatalError()
    }
}

private final class _AnyResultsViewModelBox<Concrete: DMSpotifySongSearchViewModelType>: _AnyResultsViewModelBase<Concrete.Model> {
    // variable used since we're calling mutating functions
    var concrete: Concrete
    
    init(_ concrete: Concrete) {
        self.concrete = concrete
    }
    
    override var songResults: Driver<[SongSearchResultSectionModel<Model>]> {
        return concrete.songResults
    }
}

final class AnyResultsViewModel<Model>: DMSpotifySongSearchViewModelType where Model: Representing {
    private let box: _AnyResultsViewModelBase<Model>
    
    // Initializer takes our concrete implementer of Row i.e. FileCell
    init<Concrete: DMSpotifySongSearchViewModelType>(_ concrete: Concrete) where Concrete.Model == Model {
        box = _AnyResultsViewModelBox(concrete)
    }
    
    var songResults: Driver<[SongSearchResultSectionModel<Model>]> {
        return box.songResults
    }
    
}
