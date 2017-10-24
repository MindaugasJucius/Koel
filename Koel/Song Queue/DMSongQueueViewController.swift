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
    let event: DMEvent

    fileprivate var songs: [DMSong] = []
    
    init(withEvent event: DMEvent) {
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
                self.handle(receivedSong: songRecord, withNotificationReason: songNotificationReason)
            },
            failure: { error in
                print(error.localizedDescription)
            }
        )
    }
    
    func handle(receivedSong: DMSong, withNotificationReason notificationReason: CKQueryNotificationReason) {
        // Notifications aren't received on device that the record is created. This is why there are no checks
        // to see if the received object exists in self.songs array
        
        switch notificationReason {
        case .recordCreated:
            let pathForNewRecord = IndexPath(item: songs.count, section: 0)
            songs.append(receivedSong)
            DispatchQueue.main.async {
                self.tableView.insertRows(at: [pathForNewRecord], with: .fade)
            }
        case .recordUpdated:
            
            let songIDs = songs.map { $0.recordID }
            
            let index = songIDs.index(where: { $0 == receivedSong.recordID } )
            
            guard let matchingIndex = index else {
                return
            }
            
            songs.remove(at: matchingIndex)
            songs.insert(receivedSong, at: matchingIndex)
            let pathForUpdatedRecord = IndexPath(item: matchingIndex, section: 0)
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [pathForUpdatedRecord], with: .right)
            }
        case .recordDeleted:
            print("wat")
        }
    }
    
    func fetchAllSongs() {

        songManager.fetchSongs(
            forEventID: event.recordID,
            completion: { [weak self] songRecords in
                DispatchQueue.main.async {
                    self?.songs = songRecords
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
        let song = DMSong(hasBeenPlayed: false,
                          eventID: event.recordID,
                          spotifySongID: "dankid")
        
        songManager.save(
            aSong: song,
            completion: { [unowned self] savedSong in
                let pathForNewRecord = IndexPath(item: self.songs.count, section: 0)
                self.songs.append(savedSong)
                DispatchQueue.main.async {
                    self.tableView.insertRows(at: [pathForNewRecord], with: .middle)
                }
            },
            failure: { error in
                print(error.localizedDescription)
            }
        )
    }
    
}

extension DMSongQueueViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID, for: indexPath)
        let songRecord = self.songs[indexPath.row]
        let cellTitle = "A song modified at \(songRecord.modificationDate?.description ?? "date doesn't exist")"
        cell.textLabel?.text = cellTitle
        return cell
    }
    
}
