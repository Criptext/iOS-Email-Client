//
//  CIDSchemeHandler.swift
//  iOS-Email-Client
//
//  Created by Jorge on 1/24/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import WebKit
import RealmSwift
import SwiftSoup
import Photos

class CIDSchemeHandler : NSObject,WKURLSchemeHandler {
    
    var attachments : List<File>?
    var taskMap = [String: WKURLSchemeTask]()
    let fileManager = CriptextFileManager()
    let defaults = CriptextDefaults()
    var activeAccount:Account!
    
    init(attachments: List<File>?) {
        self.attachments = attachments
        super.init()
        fileManager.delegate = self
        activeAccount = DBManager.getAccountByUsername(defaults.activeAccount!)
        fileManager.token = activeAccount.jwt
    }
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        print("AUIDA!!!!!!!!!")
        DispatchQueue.global().async {
            if let url = urlSchemeTask.request.url, url.scheme == "cid" {
                if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems {
                    for queryParams in queryItems {
                        //example : custom-scheme:// path ? type=remote & url=http://placehold.it/120x120&text=image1
                        if queryParams.name == "type" && queryParams.value == "remote" {
                            let queryItem = queryItems.filter({ $0.name == "src" })
                            let file = self.attachments!.filter( {($0.cid == queryItem[0].value)} ).first
                            if let myFile = file,
                                let cid = myFile.cid {
                                self.taskMap[cid] = urlSchemeTask
                                PHPhotoLibrary.requestAuthorization({ (status) in
                                    DispatchQueue.main.async { [weak self] in
                                        guard let weakSelf = self else {
                                            return
                                        }
                                        switch status {
                                        case .authorized:
                                            if(!myFile.fileKey.isEmpty){
                                                let keys = File.getKeyAndIv(key: myFile.fileKey)
                                                weakSelf.fileManager.setEncryption(id: myFile.emailId, key: keys.0, iv: keys.1)
                                            }
                                            weakSelf.fileManager.registerFile(file: myFile)
                                            break
                                        default:
                                            urlSchemeTask.didFailWithError(CriptextError(message: String.localize("ACCESS_DENIED")))
                                            break
                                        }
                                    }
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        urlSchemeTask.didFailWithError(CriptextError(message: "ya valio"))
    }
}

extension CIDSchemeHandler : CriptextFileDelegate, UIDocumentInteractionControllerDelegate {
    func uploadProgressUpdate(file: File, progress: Int) {
        
    }
    
    func fileError(message: String) {
        let alertPopover = GenericAlertUIPopover()
        alertPopover.myTitle = String.localize("FILE_ERROR")
        alertPopover.myMessage = message
    }
    
    func finishRequest(file: File, success: Bool) {
        if(success){
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(file.name)
            let viewer = UIDocumentInteractionController(url: fileURL)
            viewer.delegate = self
            viewer.presentPreview(animated: true)
            self.taskMap[file.cid!]?.didReceive(try! Data(contentsOf: fileURL))
            self.taskMap[file.cid!]?.didFinish()
        }
    }
}
