//
//  ViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/12/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit
import CloudKit

private let CellID = "CellID"

class ViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
    let eventManager = DMEventManager(withUserManager: DMUserManager())
    
    let urlSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    fileprivate var records: [CKRecord] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateSongs), name: SongsUpdateNotificationName, object: nil)
        self.tableView.dataSource = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellID)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func updateSongs() {
        guard let currentEvent = DMUserDefaultsHelper.CurrentEventRecord else {
            return
        }
        eventManager.fetchSongs(
            forEventID: currentEvent.recordID,
            completion: { [weak self] songRecords in
                DispatchQueue.main.async {
                    self?.records = songRecords
                }
                print(songRecords)
            },
            failure: { error in
                print(error.localizedDescription)
            }
        )
    }
    
    @IBAction func updateSongList(_ sender: UIButton) {
        updateSongs()
    }
    
    @IBAction func createEvent(_ sender: UIButton) {
        eventManager.createEvent()
    }
    
    @IBAction func addSong(_ sender: UIButton) {
        guard let currentEvent = DMUserDefaultsHelper.CurrentEventRecord else { return }
        let song = DMSong(hasBeenPlayed: false, eventID: currentEvent.recordID, spotifySongID: "dankid")
        eventManager.save(aSong: song) {
            print("lul")
        }
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID, for: indexPath)
        let songRecord = self.records[indexPath.row]
        let cellTitle = "A song created at \(String(describing: songRecord.creationDate!.description))"
        cell.textLabel?.text = cellTitle
        return cell
    }
    
}
