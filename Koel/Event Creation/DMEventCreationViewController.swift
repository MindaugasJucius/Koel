//
//  DMEventCreationViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/18/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import CloudKit

private let CellID = "CellID"

class DMEventCreationViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
    fileprivate let eventManager = DMEventManager()
    private let userManager = DMUserManager()
    
    fileprivate var events: [DMEvent] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - INJECTION
    override func injected() {
        viewDidLoad()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellID)
        eventManager.fetchAllEvents(
            success: { [unowned self] events in
                DispatchQueue.main.async {
                    self.events = events
                    self.tableView.reloadData()
                }
            },
            failure: { error in
                print(error.localizedDescription)
            }
        )
    }

    fileprivate func performEventJoin(withEvent event: DMEvent) {
        userManager.join(
            event: event, joined: { [unowned self] joinedUser in
                print("User joined an event. ID \(event.id.recordName)")
                let songQueue = DMSongQueueViewController(withEvent: event)
                DispatchQueue.main.async {
                    self.present(songQueue, animated: true, completion: nil)
                }
            },
            failure: { error in
                print("An error occurred while joining an event \(error.localizedDescription)")
            }
        )
    }
    
}

extension DMEventCreationViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID, for: indexPath)
        let event = self.events[indexPath.row]
        let cellTitle = "Event: \(event.name) with id \(event.id.recordName)"
        cell.textLabel?.text = cellTitle
        return cell
    }
    
}

extension DMEventCreationViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let eventToJoin = self.events[indexPath.row]
        performEventJoin(withEvent: eventToJoin)
    }
    
}
