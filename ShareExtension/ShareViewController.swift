//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Allisson on 11/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import UIKit
import Social
import RichEditorView
import CLTokenInputView
import RealmSwift
import MobileCoreServices

class ShareViewController: UIViewController {
    
    @IBOutlet weak var composerUIView: ComposerUIView!
    var account: Account?
    var myAccount: Account!
    var fileManager = CriptextFileManager()
    
    override func viewDidLoad() {
        configRealm()
        getAccount()
        composerUIView.initialLoad()
        composerUIView.delegate = self
        composerUIView.attachmentsTableView.delegate = self
        composerUIView.attachmentsTableView.dataSource = self
        let nib = UINib(nibName: "AttachmentTableViewCell", bundle: nil)
        composerUIView.attachmentsTableView.register(nib, forCellReuseIdentifier: "attachmentCell")
        fileManager.token = myAccount.jwt
        fileManager.delegate = self
        self.handleExtensionItems()
    }
    
    func handleExtensionItems() {
        let contentTypeUrl = kUTTypeURL as String
        let contentTypeImage = kUTTypeImage as String
        let contentTypeText = kUTTypePlainText as String
        let contentTypeFileUrl = kUTTypeFileURL as String
        
        guard let items = self.extensionContext?.inputItems else {
            return
        }
        for item in items {
            guard let extensionItem = item as? NSExtensionItem,
                let provider = extensionItem.attachments?.first else {
                continue
            }
            if (provider.hasItemConformingToTypeIdentifier(contentTypeText)) {
                provider.loadItem(forTypeIdentifier: contentTypeText, options: nil) { (it, error) in
                    guard let text = it as? String else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.composerUIView.addToContent(text: text)
                    }
                }
            }
            if (provider.hasItemConformingToTypeIdentifier(contentTypeImage)) {
                provider.loadItem(forTypeIdentifier: contentTypeImage, options: nil) { (it, error) in
                    guard let url = it as? URL else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.addFile(url: url)
                    }
                }
            }
            if (provider.hasItemConformingToTypeIdentifier(contentTypeUrl)) {
                provider.loadItem(forTypeIdentifier: contentTypeUrl, options: nil) { (it, error) in
                    guard let url = it as? URL else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.composerUIView.addToContent(text: url.path)
                    }
                }
            }
            if (provider.hasItemConformingToTypeIdentifier(contentTypeFileUrl)) {
                provider.loadItem(forTypeIdentifier: contentTypeFileUrl, options: nil) { (it, error) in
                    guard let url = it as? URL else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.addFile(url: url)
                    }
                }
            }
        }
    }
    
    func getAccount() {
        guard let groupDefaults = UserDefaults.init(suiteName: Env.groupApp),
            let username = groupDefaults.string(forKey: "activeAccount"),
            let account = SharedDB.getAccountByUsername(username) else {
                self.close()
                return
        }
        myAccount = account
    }
    
    func configRealm() {
        let fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Env.groupApp)!.appendingPathComponent("default.realm")
        let config = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: Env.databaseVersion)
        Realm.Configuration.defaultConfiguration = config
    }
    
    func addFile(url: URL){
        let filename = url.lastPathComponent
        self.fileManager.registerFile(filepath: url.path, name: filename, mimeType: File.mimeTypeForPath(path: filename))
        self.composerUIView.attachmentsTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
    }
}

extension ShareViewController: ComposerDelegate {
    func close() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

extension ShareViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileManager.registeredFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "attachmentCell", for: indexPath) as! AttachmentTableCell
        cell.setFields(fileManager.registeredFiles[indexPath.row])
        cell.iconDownloadImageView.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
}

extension ShareViewController: CriptextFileDelegate {
    func uploadProgressUpdate(file: File, progress: Int) {
        guard let attachmentCell = getCellForFile(file) else {
            return
        }
        attachmentCell.markImageView.isHidden = true
        attachmentCell.progressView.isHidden = false
        attachmentCell.progressView.setProgress(Float(progress)/100.0, animated: true)
    }
    
    func finishRequest(file: File, success: Bool) {
        guard let attachmentCell = getCellForFile(file) else {
            return
        }
        attachmentCell.setMarkIcon(success: success)
    }
    
    func getCellForFile(_ file: File) -> AttachmentTableCell? {
        guard let index = fileManager.registeredFiles.index(where: {$0.token == file.token}),
            let cell = self.composerUIView.attachmentsTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? AttachmentTableCell else {
                return nil
        }
        return cell
    }
}
