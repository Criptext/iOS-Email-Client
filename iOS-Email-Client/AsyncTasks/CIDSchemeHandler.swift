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
        guard let url = urlSchemeTask.request.url, url.scheme == "cid" else {
            return
        }
        let cid = url.absoluteString.replacingOccurrences(of: "cid:", with: "")
        self.taskMap[cid] = urlSchemeTask
        guard let file = DBManager.getFile(cid: cid) else {
                return
        }
        if(!file.fileKey.isEmpty){
            let keys = File.getKeyAndIv(key: file.fileKey)
            self.fileManager.setEncryption(id: file.emailId, key: keys.0, iv: keys.1)
        }
        self.fileManager.registerFile(file: file)
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        urlSchemeTask.didFailWithError(CriptextError(message: "ya valio"))
    }
}

extension CIDSchemeHandler : CriptextFileDelegate, UIDocumentInteractionControllerDelegate {
    func uploadProgressUpdate(file: File, progress: Int) {
        print("descargando")
    }
    
    func fileError(message: String) {
        let alertPopover = GenericAlertUIPopover()
        alertPopover.myTitle = String.localize("FILE_ERROR")
        alertPopover.myMessage = message
    }
    
    func finishRequest(file: File, success: Bool) {
        if(success){
            guard let cid = file.cid,
                let task = self.taskMap[cid] else {
                    return
            }
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(file.name)
            
            task.didReceive(URLResponse(url: documentsURL, mimeType: file.mimeType, expectedContentLength: file.size, textEncodingName: file.name))
            task.didReceive(try! Data(contentsOf: fileURL))
            task.didFinish()
        }
    }
}
