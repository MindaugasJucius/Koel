//
//  DMSpotifyTracksViewController.swift
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

class DMSpotifyTracksViewController: UIViewController, BindableType, Themeable {
    
    typealias ViewModelType = DMSpotifySongSearchViewModelType

    let viewModel: ViewModelType
    let themeManager: ThemeManager

    private let disposeBag = DisposeBag()
    
    //MARK: UI Elements
    
    private var addSongsButton: DMKoelButton
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.clipsToBounds = false
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsMultipleSelection = true
        tableView.register(DMSpotifySongTableViewCell.self,
                           forCellReuseIdentifier: DMSpotifySongTableViewCell.reuseIdentifier)
        tableView.register(DMKoelEmptyPlaceholderTableViewCell.self,
                           forCellReuseIdentifier: DMKoelEmptyPlaceholderTableViewCell.reuseIdentifier)
        return tableView
    }()
    
    private let tableViewLoadingFooter: DMKoelLoadingView
    
    private let refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        let title = UIConstants.strings.refreshCache
        refreshControl.attributedTitle = NSAttributedString(string: title)
        return refreshControl
    }()
    
    //MARK: Common observables
    
    private lazy var prefetchTrigger: Observable<Bool> = {
        let willEndDraggingTargetOffset = tableView.rx.willEndDragging.map { $0.1 }
        let prefetchTrigger = willEndDraggingTargetOffset.withLatestFrom(viewModel.isLoading) { (mutableOffset, loading) -> Bool in
                guard !loading else {
                    return false
                }
            
                var targetOffset = mutableOffset.pointee
                let shouldTrigger = self.shouldPrefetchTrigger(withTargetOffset: targetOffset)
            
                if shouldTrigger {
                    targetOffset = CGPoint(x: 0, y: targetOffset.y + DMKoelLoadingView.height)
                }
            
                return shouldTrigger
            }
            .startWith(true)
            .filter { $0 }
        return prefetchTrigger.share()
    }()
    
    init(withViewModel viewModel: DMSpotifySongSearchViewModelType, themeManager: ThemeManager) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.tableViewLoadingFooter = DMKoelLoadingView(themeManager: themeManager)
        self.addSongsButton = DMKoelButton(themeManager: themeManager)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindThemeManager()
        title = UIConstants.strings.searchSongs
        
        view.addSubview(tableView)
        tableView.refreshControl = refreshControl

        let tableViewConstraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.readableContentGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.readableContentGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(tableViewConstraints)
        
        view.addSubview(addSongsButton)
        addSongsButton.setTitle(UIConstants.strings.addSelectedSongs, for: .normal)
        addSongsButton.addConstraints(inSuperview: view)
        self.tableView.tableFooterView = tableViewLoadingFooter

    }
    
    func bindThemeManager() {
        themeNavigationBar()
            .drive()
            .disposed(by: disposeBag)
        
        themeViewColors()
            .drive()
            .disposed(by: disposeBag)
    }
    
}

extension DMSpotifyTracksViewController {
    
    func bindViewModel() {
        addSongsButton.rx.action = viewModel.queueSelectedSongs
        
        let dataSource = DMSpotifyTracksViewController.spotifySongDataSource(withViewModel: self.viewModel)
        
        viewModel.songResults
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.queueSelectedSongs.executing
            .filter { $0 }
            .debounce(0.3, scheduler: MainScheduler.instance)
            .do(onNext: { _ in
                self.tableView.indexPathsForSelectedRows?.forEach {
                    self.tableView.deselectRow(at: $0, animated: false)
                }
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelSelected(SectionItem.self)
            .subscribe(viewModel.sectionItemSelected.inputs)
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelDeselected(SectionItem.self)
            .subscribe(viewModel.sectionItemDeselected.inputs)
            .disposed(by: disposeBag)
        
        bindLoadingTrigger()
        bindLoadingFooterView()
        bindRefreshView()
    }
    
    private func bindLoadingTrigger() {
        rx.methodInvoked(#selector(UIViewController.viewDidAppear(_:)))
            .take(1)
            .do { [unowned self] in
                self.prefetchTrigger
                    .map { _ in }
                    .debounce(0.1, scheduler: MainScheduler.instance)
                    .bind(to: self.viewModel.offsetTriggerObserver)
                    .disposed(by: self.disposeBag)
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    private func bindLoadingFooterView() {
        viewModel.isLoading
            .do(onNext: { loading in self.adjustFooter(toVisible: loading) })
            .drive(tableViewLoadingFooter.isAnimating)
            .disposed(by: self.disposeBag)
    }
    
    private func bindRefreshView() {
        viewModel.isLoading
            .do(onNext: { isLoading in
                // Disable UIRefreshControl if loading
                if isLoading {
                    self.tableView.refreshControl = nil
                } else {
                    self.tableView.refreshControl = self.refreshControl
                }
            })
            .drive()
            .disposed(by: disposeBag)
        
        viewModel.isRefreshing
            .filter { !$0 }
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        
        refreshControl.rx.controlEvent(.valueChanged).asObservable()
            .debug("what", trimOutput: true)
            .bind(to: viewModel.refreshTriggerObserver)
            .disposed(by: disposeBag)
    }
}

extension DMSpotifyTracksViewController {
    
    //MARK: - Helpers
    
    private func shouldPrefetchTrigger(withTargetOffset targetOffset: CGPoint) -> Bool {
        let translation = self.tableView.panGestureRecognizer.velocity(in: nil)
        let draggingDownwards = translation.y < 0
        
        if draggingDownwards {
            return self.tableView.isNearBottomEdge(contentOffset: targetOffset)
        } else {
            return self.tableView.isNearBottomEdge(contentOffset: targetOffset, edgeOffset: 0)
        }
    }
    
    private func adjustFooter(toVisible visible: Bool) {
        if visible {
            tableView.tableFooterView?.frame = DMKoelLoadingView.frame
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: DMKoelLoadingView.height, right: 0)
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.tableFooterView?.frame = .zero
                self.tableView.contentInset = .zero
            })
        }
    }
    
}

extension DMSpotifyTracksViewController {
    
    static func spotifySongDataSource(withViewModel viewModel: DMSpotifySongSearchViewModelType) -> RxTableViewSectionedAnimatedDataSource<SongSearchResultSectionModel> {
        
        return RxTableViewSectionedAnimatedDataSource<SongSearchResultSectionModel>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .none,
                                                           reloadAnimation: .none,
                                                           deleteAnimation: .none),
            configureCell: { (dataSource, tableView, indexPath, element) -> UITableViewCell in
                switch dataSource[indexPath] {
                case let .songSectionItem(song: item):
                    let cell = tableView.dequeueReusableCell(withIdentifier: DMSpotifySongTableViewCell.reuseIdentifier,
                                                             for: indexPath) as! DMSpotifySongTableViewCell
                    cell.configure(withSong: item)
                    return cell
                case .emptySectionItem:
                    let cell = tableView.dequeueReusableCell(withIdentifier: DMKoelEmptyPlaceholderTableViewCell.reuseIdentifier,
                                                             for: indexPath) as! DMKoelEmptyPlaceholderTableViewCell
                    cell.placeholderImage = #imageLiteral(resourceName: "empty song screen placeholder")
                    cell.placeholderText = UIConstants.strings.noSearchResults
                    return cell
                case .initialSectionItem:
                    let cell = tableView.dequeueReusableCell(withIdentifier: DMKoelEmptyPlaceholderTableViewCell.reuseIdentifier,
                                                             for: indexPath) as! DMKoelEmptyPlaceholderTableViewCell
                    cell.placeholderImage = #imageLiteral(resourceName: "empty song screen placeholder")
                    cell.placeholderText = UIConstants.strings.enterToSearch
                    return cell
                }
            },
            titleForHeaderInSection: { dataSource, index in
                if dataSource.sectionModels[index].identity == SectionType.songs.rawValue {
                    return UIConstants.strings.userSavedTracks
                }
                return nil
            }
        )
    }
    
}
