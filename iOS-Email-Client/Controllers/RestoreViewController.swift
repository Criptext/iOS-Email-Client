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
        contentView.setRestoring()
        restore()
    }
}

extension RestoreViewController: RestoreDelegate {
    
    func handleDownload() {
        guard let url = containerUrl?.appendingPathComponent("backup.db") else {
            contentView.setError()
            return
        }
        query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        query.predicate = NSPredicate(format: "%K ==[cd] %@", NSMetadataItemPathKey, url.path)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdate), name: NSNotification.Name.NSMetadataQueryDidUpdate, object: nil)
        query.enableUpdates()
        query.start()
    }
    
    @objc func didUpdate(not: NSNotification) {
        guard let item = (not.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem])?.first else {
            return
        }
        self.query.disableUpdates()
        let isDownloading = (item.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey) as? NSNumber)?.boolValue ?? false
        let downloadStatus = (item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String) ?? NSMetadataUbiquitousItemDownloadingStatusNotDownloaded
        if !isDownloading {
            if downloadStatus == NSMetadataUbiquitousItemDownloadingStatusCurrent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.restoreFile()
                }
                self.query.stop()
            }
        }
        self.query.enableUpdates()
    }
    
    func cancelRestore() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func retryRestore() {
        contentView.setRestoring()
        self.restore()
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
            
            contentView.setRestoring()
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
        
        guard let myUrl = containerUrl?.appendingPathComponent("backup.db") else {
            contentView.setError()
            return
        }
        
        guard let decompressedPath = try? AESCipher.compressFile(path: myUrl.path, outputName: StaticFile.unzippedDB.name, compress: false) else {
            contentView.setError()
            return
        }
        
        let restoreTask = RestoreDBAsyncTask(path: decompressedPath, username: myAccount.username, initialProgress: 5)
        restoreTask.start(progressHandler: { (progress) in
            self.contentView.animateProgress(Double(progress), 0.5, completion: {})
        }) {
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
                inboxVC.loadMails(since: Date(), clear: true, limit: 0)
                inboxVC.showSnackbar(String.localize("RESTORE_SUCCESS"), attributedText: nil, buttons: "", permanent: false)
            }
        })
    }
}
