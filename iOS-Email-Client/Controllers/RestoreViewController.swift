//
//  RestoreViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 4/9/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class RestoreViewController: UIViewController {
    var contentView: RestoreUIView {
        return self.view as! RestoreUIView
    }
    var myAccount: Account!
    var query: NSMetadataQuery!
    var localUrl: URL!
    var containerUrl: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(myAccount.email)
    }
    var isLocal: Bool {
        get {
            return (localUrl != nil)
        }
    }
    var isEncrypted: Bool {
        get {
            return (localUrl.pathExtension == Env.linkFileExtensions.encrypted.rawValue)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        
        contentView.delegate = self
        
        contentView.applyTheme(view: self.view)
        if(isLocal){
            guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: self.localUrl.path) else {
                contentView.setError(isLocal: self.isLocal, isEncrypted: self.isEncrypted)
                return
            }
            let fileSize = Int(truncating: fileAttributes[.size] as! NSNumber)
            let lastDate = Date(timeIntervalSinceReferenceDate: (fileAttributes[.modificationDate] as! NSDate).timeIntervalSinceReferenceDate)
            contentView.setFound(email: self.myAccount.email, lastDate: lastDate, size: fileSize, isLocal: self.isLocal, isEncrypted: self.isEncrypted)
        } else {
            contentView.setRestoring(isLocal: isLocal)
            restore(password: nil)
        }
    }
}

extension RestoreViewController: RestoreDelegate {
    
    func handleDownload() {
        guard let url = containerUrl?.appendingPathComponent("backup.db") else {
            contentView.setError(isLocal: self.isLocal, isEncrypted: self.isEncrypted)
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
                    self.restoreFile(password: nil)
                }
                self.query.stop()
            }
        }
        self.query.enableUpdates()
    }
    
    func cancelRestore() {
        UIApplication.shared.isIdleTimerDisabled = false
        self.dismiss(animated: true, completion: nil)
    }
    
    func retryRestore(password: String?) {
        contentView.setRestoring(isLocal: self.isLocal)
        self.restore(password: password)
    }
    
    func restore(password: String?) {
        if(self.isLocal){
            restoreFile(password: password)
        } else {
            guard let myUrl = containerUrl?.appendingPathComponent("backup.db") else {
                contentView.setError(isLocal: self.isLocal, isEncrypted: self.isEncrypted)
                return
            }
            do {
                var keys = Set<URLResourceKey>()
                keys.insert(.ubiquitousItemDownloadingStatusKey)
                
                let resourceValues = try myUrl.resourceValues(forKeys: keys)
                let downloadStatus = (resourceValues.allValues[.ubiquitousItemDownloadingStatusKey] as? URLUbiquitousItemDownloadingStatus) ?? .notDownloaded
                
                contentView.setRestoring(isLocal: self.isLocal)
                if downloadStatus == .current {
                    restoreFile(password: nil)
                } else {
                    try FileManager.default.startDownloadingUbiquitousItem(at: myUrl)
                    self.handleDownload()
                }
            } catch {
                self.contentView.setError(isLocal: self.isLocal, isEncrypted: self.isEncrypted)
            }
        }
    }
    
    func restoreFile(password: String?) {
        if(self.isLocal){
            var filePath = self.localUrl.path
            if let pass = password,
                let encryptPath = AESCipher.streamEncrypt(path: filePath, outputName: StaticFile.decryptedDB.name, bundle: AESCipher.KeyBundle(password: pass, salt: nil), ivData: nil, operation: kCCDecrypt) {
                contentView.setRestoring(isLocal: self.isLocal)
                self.contentView.animateProgress(Double(10), 3.0, completion: {})
                filePath = encryptPath
            }
            guard let decompressedPath = try? AESCipher.compressFile(path: filePath, outputName: StaticFile.unzippedDB.name, compress: false) else {
                contentView.setError(isLocal: self.isLocal, isEncrypted: self.isEncrypted)
                return
            }
            
            let restoreTask = RestoreDBAsyncTask(path: decompressedPath, accountId: myAccount.compoundKey, initialProgress: 10)
            restoreTask.start(progressHandler: { (progress) in
                self.contentView.animateProgress(Double(progress), 3.0, completion: {})
            }) {_ in
                self.restoreSuccess()
            }
        } else {
            guard let myUrl = containerUrl?.appendingPathComponent("backup.db") else {
                contentView.setError(isLocal: self.isLocal, isEncrypted: self.isEncrypted)
                return
            }
            
            guard let decompressedPath = try? AESCipher.compressFile(path: myUrl.path, outputName: StaticFile.unzippedDB.name, compress: false) else {
                contentView.setError(isLocal: self.isLocal, isEncrypted: self.isEncrypted)
                return
            }
            
            let restoreTask = RestoreDBAsyncTask(path: decompressedPath, accountId: myAccount.compoundKey, initialProgress: 5)
            restoreTask.start(progressHandler: { (progress) in
                self.contentView.animateProgress(Double(progress), 0.5, completion: {})
            }) {_ in
                self.restoreSuccess()
            }
        }
    }
    
    func changeFile() {
        let providerList = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        providerList.delegate = self;
        providerList.allowsMultipleSelection = false
        
        providerList.popoverPresentationController?.sourceView = self.view
        providerList.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        self.present(providerList, animated: true, completion: nil)
    }
    
    func restoreSuccess() {
        self.contentView.animateProgress(100, 2, completion: {
            UIApplication.shared.isIdleTimerDisabled = false
            guard let inboxVC = (UIApplication.shared.delegate as? AppDelegate)?.getInboxVC() else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            inboxVC.dismiss(animated: true) {
                inboxVC.loadMails(since: Date(), clear: true, limit: 0)
                inboxVC.showSnackbar(String.localize("RESTORE_SUCCESS"), attributedText: nil, permanent: false)
            }
        })
    }
}

extension RestoreViewController: UIDocumentPickerDelegate {
    
    func documentMenu(didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        //show document picker
        documentPicker.delegate = self;
        
        documentPicker.popoverPresentationController?.sourceView = self.view
        documentPicker.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let validExtensions = Env.linkFileExtensions.allValues
        
        if(!validExtensions.contains(url.pathExtension)) {
            contentView.setError(isLocal: self.isLocal, isEncrypted: self.isEncrypted)
        } else {
            self.localUrl = url
            if(self.isEncrypted){
                guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: self.localUrl.path) else {
                    contentView.setError(isLocal: self.isLocal, isEncrypted: self.isEncrypted)
                    return
                }
                let fileSize = Int(truncating: fileAttributes[.size] as! NSNumber)
                let lastDate = Date(timeIntervalSinceReferenceDate: (fileAttributes[.modificationDate] as! NSDate).timeIntervalSinceReferenceDate)
                contentView.setFound(email: self.myAccount.email, lastDate: lastDate, size: fileSize, isLocal: self.isLocal, isEncrypted: self.isEncrypted)
            } else {
                contentView.setRestoring(isLocal: self.isLocal)
                restore(password: nil)
            }
        }
    }
    
}
