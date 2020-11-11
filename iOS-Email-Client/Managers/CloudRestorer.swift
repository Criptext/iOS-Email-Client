//
//  CloudRestorer.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/6/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

protocol CloudRestorerDelegate: class {
    func error(message: String)
    func success(url: URL)
    func downloading(progress: Float)
}

class CloudRestorer {
    
    var myAccount: Account!
    weak var delegate: CloudRestorerDelegate?
    var query: NSMetadataQuery!
    var containerUrl: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(myAccount.email)
    }
    
    func check() {
        guard let myUrl = containerUrl?.appendingPathComponent("backup.db") else {
            delegate?.error(message: "Not Found")
            return
        }
        
        do {
            var keys = Set<URLResourceKey>()
            keys.insert(.ubiquitousItemDownloadingStatusKey)
            
            let resourceValues = try myUrl.resourceValues(forKeys: keys)
            let downloadStatus = (resourceValues.allValues[.ubiquitousItemDownloadingStatusKey] as? URLUbiquitousItemDownloadingStatus) ?? .notDownloaded
            
            if downloadStatus == .current {
                self.delegate?.success(url: myUrl)
            } else {
                try FileManager.default.startDownloadingUbiquitousItem(at: myUrl)
                self.handleDownload()
            }
        } catch {
            delegate?.error(message: "Not Found")
        }
    }
    
    func handleDownload() {
        guard let url = containerUrl?.appendingPathComponent("backup.db") else {
            delegate?.error(message: "Not Found")
            return
        }
        delegate?.downloading(progress: 0)
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
                guard let myUrl = containerUrl?.appendingPathComponent("backup.db") else {
                    self.delegate?.error(message: "Not Found")
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.delegate?.success(url: myUrl)
                }
                self.query.stop()
            }
        } else {
            guard (item.value(forKey: NSMetadataUbiquitousItemIsDownloadingKey) as? NSNumber)?.boolValue ?? false,
                let progress = item.value(forKey: NSMetadataUbiquitousItemPercentDownloadedKey) as? NSNumber else {
                return
            }
            self.delegate?.downloading(progress: progress.floatValue)
        }
        self.query.enableUpdates()
    }
    
}
