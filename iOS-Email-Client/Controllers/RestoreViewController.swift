//
//  RestoreViewController.swift
//  iOS-Email-Client
//
//  Created by Allisson on 4/9/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class RestoreViewController: UIViewController {
    var contentView: RestoreUIView {
        return self.view as! RestoreUIView
    }
    var myAccount: Account!
    var query: NSMetadataQuery!
    var containerUrl: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(myAccount.email)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.delegate = self
        
        contentView.applyTheme()
        contentView.setSearching()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.fetchBackupData()
        }
    }
    
    func fetchBackupData() {
        
        guard let url = containerUrl?.appendingPathComponent("backup.db") else {
            contentView.setError()
            return
        }
        
        var keys = Set<URLResourceKey>()
        keys.insert(.ubiquitousItemIsUploadedKey)
        
        do {
            let resourceValues = try url.resourceValues(forKeys: keys)
            let hasBackup = (resourceValues.allValues[.ubiquitousItemIsUploadedKey] as? Bool) ?? false
            
            if hasBackup {
                if let cloudUrl = containerUrl?.appendingPathComponent("backup.db"),
                    let attrs = try? FileManager.default.attributesOfItem(atPath: cloudUrl.path) {
                    let NSlastBackupDate = attrs[.modificationDate] as? NSDate
                    let NSlastBackupSize = attrs[.size] as? NSNumber
                    let lastBackupDate = NSlastBackupDate as Date? ?? Date()
                    let lastBackupSize = NSlastBackupSize?.intValue ?? 0
                    
                    contentView.setFound(email: myAccount.email, lastDate: lastBackupDate, size: lastBackupSize)
                } else {
                    contentView.setError()
                }
            } else {
                contentView.setMissing()
            }
        } catch {
            contentView.setError()
            return
        }
        
    }
}

extension RestoreViewController: RestoreDelegate {
    func handleDownload() {
        query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        query.predicate = NSPredicate(format: "%K ==[cd] %@", NSMetadataItemPathKey, containerUrl!.appendingPathComponent("backup.db").path)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdate), name: NSNotification.Name.NSMetadataQueryDidUpdate, object: nil)
        query.enableUpdates()
        query.start()
    }
    
    @objc func didUpdate(not: NSNotification) {
        guard let items = not.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem] else {
            return
        }
        self.query.disableUpdates()
        for mdItem in items {
            guard !((mdItem.value(forKey: NSMetadataUbiquitousItemIsDownloadingKey) as? NSNumber)?.boolValue ?? false) else {
                print("DOWNLOADED WACHIN!")
                query.stop()
                restoreFile()
                return
            }
            guard (mdItem.value(forKey: NSMetadataUbiquitousItemIsUploadingKey) as? NSNumber)?.boolValue ?? false,
                let progress = mdItem.value(forKey: NSMetadataUbiquitousItemPercentUploadedKey) as? NSNumber else {
                    return
            }
            print("Downloading Backup... \(progress.intValue)%")
        }
        self.query.enableUpdates()
    }
    
    func cancelRestore() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func retryRestore() {
        contentView.setSearching()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.fetchBackupData()
        }
    }
    
    func restore() {
        guard let myUrl = containerUrl?.appendingPathComponent("backup.db") else {
            contentView.setError()
            return
        }
        do {
            var keys = Set<URLResourceKey>()
            keys.insert(.ubiquitousItemDownloadingStatusKey)
            
            let resourceValues = try myUrl.resourceValues(forKeys: keys)
            let downloadStatus = (resourceValues.allValues[.ubiquitousItemDownloadingStatusKey] as? URLUbiquitousItemDownloadingStatus) ?? .notDownloaded
            
            if downloadStatus == .current {
                restoreFile()
            } else {
                try FileManager.default.startDownloadingUbiquitousItem(at: myUrl)
                self.handleDownload()
            }
        } catch {
            self.contentView.setError()
        }
    }
    
    func restoreFile() {
        guard let myUrl = containerUrl?.appendingPathComponent("backup.db"),
            let decompressedPath = try? AESCipher.compressFile(path: myUrl.path, outputName: StaticFile.unzippedDB.name, compress: false) else {
            contentView.setError()
            return
        }
        contentView.setRestoring()
        let restoreTask = RestoreDBAsyncTask(path: decompressedPath, username: myAccount.username, initialProgress: 5)
        restoreTask.start(progressHandler: { (progress) in
            self.contentView.animateProgress(Double(progress), 0.5, completion: {})
        }) {
            print("DONE")
            self.restoreSuccess()
        }
    }
    
    func restoreSuccess() {
        self.contentView.animateProgress(100, 2, completion: {
            guard let inboxVC = (UIApplication.shared.delegate as? AppDelegate)?.getInboxVC() else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            inboxVC.dismiss(animated: true) {
                inboxVC.refreshThreadRows()
                inboxVC.showSnackbar(String.localize("RESTORE_SUCCESS"), attributedText: nil, buttons: "", permanent: false)
            }
        })
    }
}
