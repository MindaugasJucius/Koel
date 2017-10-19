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
    
    private let eventManager = DMEventManager()
    
    fileprivate var records: [CKRecord] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellID)

        eventManager.fetchAllEvents(
            success: { [unowned self] events in
                DispatchQueue.main.async {
                    self.records = events
                    self.tableView.reloadData()
                }
            },
            failure: { error in
                print(error.localizedDescription)
            }
        )
    }

}

extension DMEventCreationViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID, for: indexPath)
        let eventRecord = self.records[indexPath.row]
        let eventName = eventRecord[EventKey.name] ?? "Event"
        let cellTitle = "\(eventName) created at \(String(describing: eventRecord.creationDate!.description))"
        cell.textLabel?.text = cellTitle
        return cell
    }
    
}
