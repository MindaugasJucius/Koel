//
//  DMFlowSelectionViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 12/3/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import Action

class DMFlowSelectionViewController: UIViewController, BindableType {

    typealias ViewModelType = DMFlowSelectionViewModel
    
    var viewModel: DMFlowSelectionViewModel
    
    //MARK: - UI elements
    
    private var koelButton = DMKoelButton()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(UIConstants.strings.createEvent, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(UIConstants.strings.searchNearby, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    required init(withViewModel viewModel: DMFlowSelectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(koelButton)
        koelButton.addConstraints(inSuperview: view)
        koelButton.setTitle(UIConstants.strings.addSong, for: .normal)
        
        view.backgroundColor = .white
        stackView.addArrangedSubview(createButton)
        stackView.addArrangedSubview(searchButton)
        view.addSubview(stackView)
        let constraints = [
            stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func bindViewModel() {
        koelButton.rx.action = viewModel.onSpotifyLogin()
        createButton.rx.action = viewModel.onCreateEvent()
        searchButton.rx.action = viewModel.onSearchEvent()
    }


}
