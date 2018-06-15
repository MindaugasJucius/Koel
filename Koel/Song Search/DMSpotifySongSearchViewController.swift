//
//  DMSpotifySongSearchViewController.swift
//  Koel
//
//  Created by Mindaugas on 25/03/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

extension UIScrollView {
    func isNearBottomEdge(edgeOffset: CGFloat = 200) -> Bool {
        return contentOffset.y + frame.size.height + edgeOffset > contentSize.height
    }

    func isNearBottomEdge(contentOffset: CGPoint, edgeOffset: CGFloat = 200) -> Bool {
        return contentOffset.y + frame.size.height + edgeOffset > contentSize.height
    }

}

class DMSpotifySongSearchViewController: UIViewController, BindableType {
    
    typealias ViewModelType = DMSpotifySongSearchViewModelType

    var viewModel: DMSpotifySongSearchViewModelType

    private let disposeBag = DisposeBag()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(UIConstants.strings.done, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsMultipleSelection = true
        tableView.register(DMSpotifySongTableViewCell.self, forCellReuseIdentifier: DMSpotifySongTableViewCell.reuseIdentifier)
        return tableView
    }()
    
    private lazy var activityControl: UIActivityIndicatorView = {
        let activityControl = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityControl.translatesAutoresizingMaskIntoConstraints = false
        return activityControl
    }()
    
    private let refreshControl = UIRefreshControl()
    
    required init(withViewModel viewModel: DMSpotifySongSearchViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        
        view.addSubview(tableView)
        
        let tableViewConstraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(tableViewConstraints)
        
        self.view.addSubview(doneButton)
        
        let buttonConstraints = [
            doneButton.leftAnchor.constraintEqualToSystemSpacingAfter(view.safeAreaLayoutGuide.leftAnchor, multiplier: 2),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        tableView.addSubview(refreshControl)

        NSLayoutConstraint.activate(buttonConstraints)
        
        view.addSubview(activityControl)
        
        let activityControlConstraints = [
            activityControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(activityControlConstraints)
    }
    
    func bindViewModel() {

        rx.methodInvoked(#selector(UIViewController.viewDidAppear(_:)))
            .take(1)
            .do { [unowned self] in
                let dataSource = DMSpotifySongSearchViewController.persistedSongDataSource(withViewModel: self.viewModel)
                
                self.viewModel.results
                    .drive(self.tableView.rx.items(dataSource: dataSource))
                    .disposed(by: self.disposeBag)
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .drive(activityControl.rx.isAnimating)
            .disposed(by: self.disposeBag)
        
        let didScrollDownwards = tableView.rx.didEndDragging
            .map { [unowned self] _ -> Bool in
                let translation = self.tableView.panGestureRecognizer.velocity(in: nil)
                return translation.y < 0
            }
        
        let offsetTrigger = tableView.rx.willEndDragging
            .map { (velocity, targetOffsetPointer) -> Bool in
                let targetOffset = targetOffsetPointer.pointee
                return self.tableView.isNearBottomEdge(contentOffset: targetOffset)
            }

        viewModel.loadNextPageOffsetTrigger = Observable.combineLatest(didScrollDownwards, offsetTrigger)
            .map { $0 && $1 }
            .startWith(true)
            .filter { $0 }
            .map { _ in }
            .asDriver(onErrorJustReturn: ())
            .debounce(0.1)
        
        tableView.rx
            .modelSelected(DMEventSong.self)
            .subscribe(viewModel.addSelectedSong.inputs)
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelDeselected(DMEventSong.self)
            .subscribe(viewModel.removeSelectedSong.inputs)
            .disposed(by: disposeBag)
        
        doneButton.rx.action = viewModel.onDone
    }
    
}

extension DMSpotifySongSearchViewController {
    
    static func persistedSongDataSource(withViewModel viewModel: DMSpotifySongSearchViewModelType) -> RxTableViewSectionedReloadDataSource<SongSection> {
        return RxTableViewSectionedReloadDataSource<SongSection>(
            configureCell: { (dataSource, tableView, indexPath, element) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: DMSpotifySongTableViewCell.reuseIdentifier, for: indexPath)
                
                guard let songCell = cell as? DMSpotifySongTableViewCell else {
                    return cell
                }
                
                songCell.configure(withSong: element)
                
                return cell
        },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
        }
        )
    }
    
    
}
