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

    func isNearBottomEdge() -> Bool {
        return contentOffset.y + frame.size.height > contentSize.height
    }
    
    func isNearBottomEdge(contentOffset: CGPoint, edgeOffset: CGFloat = 200) -> Bool {
        return contentOffset.y + frame.size.height + edgeOffset >= contentSize.height
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
        tableView.register(DMSpotifySongTableViewCell.self,
                           forCellReuseIdentifier: DMSpotifySongTableViewCell.reuseIdentifier)
        tableView.register(DMKoelEmptyPlaceholderTableViewCell.self,
                           forCellReuseIdentifier: DMKoelEmptyPlaceholderTableViewCell.reuseIdentifier)
        return tableView
    }()
    
    private lazy var willEndDraggingTargetOffset = tableView.rx.willEndDragging.map { $0.1 }
    
    private let tableViewLoadingFooter = DMKoelLoadingView()
    
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
        tableView.addSubview(refreshControl)
        
        let tableViewConstraints = [
            tableView.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.readableContentGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.readableContentGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(tableViewConstraints)
        
        view.addSubview(doneButton)
        let buttonConstraints = [
            doneButton.leftAnchor.constraintEqualToSystemSpacingAfter(view.safeAreaLayoutGuide.leftAnchor, multiplier: 2),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(buttonConstraints)
        
        self.tableView.tableFooterView = tableViewLoadingFooter
    }
    
    func bindViewModel() {
        rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
            .take(1)
            .do { [unowned self] in
                let dataSource = DMSpotifySongSearchViewController.persistedSongDataSource(withViewModel: self.viewModel)
                
                self.viewModel.songResults
                    .drive(self.tableView.rx.items(dataSource: dataSource))
                    .disposed(by: self.disposeBag)
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelSelected(DMEventSong.self)
            .subscribe(viewModel.addSelectedSong.inputs)
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelDeselected(DMEventSong.self)
            .subscribe(viewModel.removeSelectedSong.inputs)
            .disposed(by: disposeBag)
        
        doneButton.rx.action = viewModel.onDone
        
        bindLoadingTrigger()
        bindLoadingView()
    }
    
    func bindLoadingTrigger() {
        let prefetchTrigger = willEndDraggingTargetOffset.withLatestFrom(viewModel.isLoading) { (mutableOffset, loading) -> Bool in
                guard !loading else {
                    return false
                }
                let targetOffset = mutableOffset.pointee
                let translation = self.tableView.panGestureRecognizer.velocity(in: nil)
                let downwards = translation.y < 0
                if downwards {
                    return self.tableView.isNearBottomEdge(contentOffset: targetOffset)
                } else {
                    return self.tableView.isNearBottomEdge(contentOffset: targetOffset, edgeOffset: 0)
                }
            }
            .filter { $0 }
        
        prefetchTrigger
            .map { _ in }
            .asDriver(onErrorJustReturn: ())
            .debounce(0.1)
            .drive(viewModel.offsetTriggerRelay)
            .disposed(by: disposeBag)
    }
    
    func bindLoadingView() {
        willEndDraggingTargetOffset.withLatestFrom(viewModel.isLoading) { (mutableOffset, loading) -> () in
                guard !loading else {
                    return
                }
                var currentTargetOffset = mutableOffset.pointee
                if self.tableView.isNearBottomEdge(contentOffset: currentTargetOffset) {
                    self.tableView.tableFooterView?.frame = DMKoelLoadingView.frame
                    self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: DMKoelLoadingView.height, right: 0)
                    currentTargetOffset = CGPoint(x: 0, y: currentTargetOffset.y + DMKoelLoadingView.height)
                }
            }
            .subscribe()
            .disposed(by: disposeBag)

        viewModel.isLoading
            .debug("loading", trimOutput: false)
            .drive(tableViewLoadingFooter.isAnimating)
            .disposed(by: self.disposeBag)
        
        viewModel.isLoading.filter { !$0 }
            .do(
                onNext: { [unowned self] _ in
                    UIView.animate(withDuration: 0.3, animations: {
                        self.tableView.tableFooterView?.frame = .zero
                        self.tableView.contentInset = .zero
                    })
                    return
                }
            )
            .drive()
            .disposed(by: self.disposeBag)

        refreshControl.rx.controlEvent(.valueChanged).asObservable()
            .debug("refresh", trimOutput: false)
            .bind(to: viewModel.refreshTriggerRelay)
            .disposed(by: self.disposeBag)
    }
    
}

extension DMSpotifySongSearchViewController {
    
    static func persistedSongDataSource(withViewModel viewModel: DMSpotifySongSearchViewModelType) -> RxTableViewSectionedReloadDataSource<SongSectionModel> {
        return RxTableViewSectionedReloadDataSource<SongSectionModel>(
            configureCell: { (dataSource, tableView, indexPath, element) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: DMSpotifySongTableViewCell.reuseIdentifier,
                                                         for: indexPath)
                switch dataSource[indexPath] {
                case let .songSectionItem(song: item):
                    (cell as? DMSpotifySongTableViewCell)?.configure(withSong: item)
                    return cell
                case .emptySectionItem:
                    let cell = tableView.dequeueReusableCell(withIdentifier: DMKoelEmptyPlaceholderTableViewCell.reuseIdentifier,
                                                             for: indexPath)
                    return cell
                default:
                    return cell
                }
            }
        )
    }
    
    
}
