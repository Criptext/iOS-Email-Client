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
    
    override func viewDidLoad() {
        configRealm()
        getAccount()
        handleExtensionItems()
        composerUIView.initialLoad()
        composerUIView.delegate = self
        self.composerUIView.addToContent(text: "Pepito")
        self.composerUIView.addToContent(text: " PELON")
    }
    
    func handleExtensionItems() {
        _ = kUTTypeURL as String
        let contentTypeImage = kUTTypeImage as String
        let contentTypeText = kUTTypePlainText as String
        
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
                        self.composerUIView.addToContent(text: url.path)
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
}

extension ShareViewController: ComposerDelegate {
    func close() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
