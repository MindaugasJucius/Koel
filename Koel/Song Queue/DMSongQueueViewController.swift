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

class DMSongQueueViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
    let songManager: DMSongManager
    let event: CKRecord
    
    fileprivate var records: [CKRecord] = []
    
    init(withEvent event: CKRecord) {
        self.event = event
        self.songManager = DMSongManager(withEvent: event)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        songManager.fetchASong(
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

        songManager.fetchSongs(
            forEventID: event.recordID,
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
    
    @IBAction func addSong(_ sender: UIButton) {
        let song = DMSong(hasBeenPlayed: false, id: nil, eventID: event.recordID, spotifySongID: "dankid")
        songManager.save(aSong: song) { song in
            print("lul")
            
        }
    }
    
}

extension DMSongQueueViewController: UITableViewDataSource {
    
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
