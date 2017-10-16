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
    
    fileprivate var records: [CKRecord] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateSongs(withNotification:)), name: SongsUpdateNotificationName, object: nil)
        self.tableView.dataSource = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellID)
        fetchAllSongs()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func updateSongs(withNotification notification: Notification) {
        guard let songIDRecord = notification.userInfo?[DMSong.notificationSongIDKey] as? CKRecordID,
        let songNotificationReason = notification.userInfo?[DMSong.notificationReasonSongKey] as? CKQueryNotificationReason else {
            return
        }
        print(songNotificationReason)
        eventManager.fetchASong(
            withSongRecordID: songIDRecord,
            completion: { [unowned self] songRecord in
                self.handle(songRecord: songRecord, withNotificationReason: songNotificationReason)
            },
            failure: { error in
                print(error.localizedDescription)
            }
        )
    }
    
    func handle(songRecord: CKRecord, withNotificationReason notificationReason: CKQueryNotificationReason) {
        switch notificationReason {
        case .recordCreated:
            let pathForNewRecord = IndexPath(item: records.count, section: 0)
            records.append(songRecord)
            DispatchQueue.main.async {
                self.tableView.insertRows(at: [pathForNewRecord], with: .fade)
            }
        case .recordUpdated:
            for (index, existingSongRecord) in records.enumerated() {
                guard existingSongRecord.recordID == songRecord.recordID else {
                    continue
                }
                records.remove(at: index)
                records.insert(songRecord, at: index)
                let pathForUpdatedRecord = IndexPath(item: index, section: 0)
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [pathForUpdatedRecord], with: .right)
                }
            }
        case .recordDeleted:
            print("wat")
        }
    }
    
    @IBAction func updateSongList(_ sender: UIButton) {
        fetchAllSongs()
    }
    
    func fetchAllSongs() {
        guard let currentEvent = DMUserDefaultsHelper.CurrentEventRecord else {
            return
        }
        eventManager.fetchSongs(
            forEventID: currentEvent.recordID,
            completion: { [weak self] songRecords in
                DispatchQueue.main.async {
                    self?.records = songRecords
                    self?.tableView.reloadData()
                }
                print("fetched \(songRecords.count) songs")
            },
            failure: { error in
                print(error.localizedDescription)
            }
        )
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
        let cellTitle = "A song modified at \(String(describing: songRecord.modificationDate!.description))"
        cell.textLabel?.text = cellTitle
        return cell
    }
    
}
