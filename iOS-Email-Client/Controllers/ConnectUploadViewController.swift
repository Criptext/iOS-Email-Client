//
//  ConnectUploadViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftWebSocket

class ConnectUploadViewController: UIViewController{
    
    let keyData     = AESCipher.generateRandomBytes()
    let ivData      = AESCipher.generateRandomBytes()
    
    enum Status {
        case none
        case processing
        case processed
    }
    
    @IBOutlet var connectUIView: ConnectUIView!
    var linkData: LinkData!
    var myAccount: Account!
    var mailboxDelegate: WebSocketManagerDelegate?
    var databasePath : String?
    var keyBundleReady = false
    var scheduleWorker = ScheduleWorker(interval: 5.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mailboxDelegate = WebSocketManager.sharedInstance.delegate
        WebSocketManager.sharedInstance.delegate = self
        connectUIView.initialLoad(email: "\(myAccount.username)\(Constants.domain)")
        scheduleWorker.delegate = self
        self.connectUIView.goBackButton.isHidden = true
        APIManager.linkAccept(randomId: linkData.randomId, token: myAccount.jwt) { (responseData) in
            guard case let .SuccessDictionary(data) = responseData,
                let deviceId = data["deviceId"] as? Int32 else {
                self.showErrorAlert(message: "Unable to accept device")
                return
            }
            self.connectUIView.goBackButton.isHidden = false
            self.connectUIView.messageLabel.text = "Waiting for \(self.linkData.deviceName)..."
            self.linkData.deviceId = deviceId
            self.createDBFile(deviceId: deviceId)
            self.scheduleWorker.start()
        }
        connectUIView.goBack = {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        scheduleWorker.cancel()
        WebSocketManager.sharedInstance.delegate = mailboxDelegate
    }
    
    func continueUpload(){
        guard let path = self.databasePath,
            keyBundleReady else {
                return
        }
        uploadDBFile(path: path)
    }
    
    func showErrorAlert(message: String){
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            self.dismiss(animated: true)
        })
        self.showAlert("Error Linking Device", message: message, style: .alert, actions: [okAction])
    }
    
    func createDBFile(deviceId: Int32){
        CreateCustomJSONFileAsyncTask().start { (error, url) in
            guard let myUrl = url else {
                self.showErrorAlert(message: "Unable to retrieve db file path")
                return
            }
            guard let outputPath = AESCipher.streamEncrypt(path: myUrl.path, outputName: "secure-db", keyData: self.keyData, ivData: self.ivData, operation: kCCEncrypt) else {
                self.showErrorAlert(message: "Unable to encrypt db file")
                return
            }
            self.databasePath = outputPath
            self.continueUpload()
        }
    }
    
    func uploadDBFile(path: String){
        connectUIView.goBackButton.isHidden = true
        connectUIView.messageLabel.text = "Uploading emails..."
        guard let inputStream = InputStream.init(fileAtPath: path),
            let fileAttributes = try? FileManager.default.attributesOfItem(atPath: path) else {
                self.showErrorAlert(message: "Unable to open file stream")
                return
        }
        let fileSize = Int(truncating: fileAttributes[.size] as! NSNumber)
        APIManager.uploadLinkDBFile(dbFile: inputStream, randomId: linkData.randomId, size: fileSize, token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                self.showErrorAlert(message: "Unable to upload file")
                return
            }
            self.encryptAndSendKeys()
        }
    }
    
    func encryptAndSendKeys(){
        guard let deviceId = linkData.deviceId else {
            self.showErrorAlert(message: "Unable to encrypt key")
            return
        }
        var data: Data?
        tryBlock {
            data = SignalHandler.encryptData(data: self.keyData, deviceId: deviceId, recipientId: self.myAccount.username, account: self.myAccount)
        }
        guard let encryptedData = data else {
            self.showErrorAlert(message: "Unable to encrypt key")
            return
        }
        self.sendSuccessData(deviceId: deviceId, encryptedKey: encryptedData.base64EncodedString())
    }
    
    func sendSuccessData(deviceId: Int32, encryptedKey: String){
        let params = [
            "deviceId": deviceId,
            "key": encryptedKey
        ] as [String: Any]
        APIManager.linkDataAddress(params: params, token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                self.showErrorAlert(message: "Unable to post address")
                return
            }
            self.connectUIView.handleSuccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                self.dismiss(animated: true)
            })
        }
    }
}

extension ConnectUploadViewController: ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void) {
        guard let deviceId = linkData.deviceId else {
            completion(true)
            self.showErrorAlert(message: "Unable to get Keys")
            return
        }
        APIManager.getKeybundle(deviceId: deviceId, token: myAccount.jwt) { (responseData) in
            guard case let .SuccessDictionary(keys) = responseData else {
                completion(false)
                return
            }
            completion(true)
            let ex = tryBlock {
                SignalHandler.buildSession(recipientId: self.myAccount.username, deviceId: deviceId, keys: keys, account: self.myAccount)
            }
            guard ex == nil else {
                self.showErrorAlert(message: "Unable to create session")
                return
            }
            self.keyBundleReady = true
            self.continueUpload()
        }
    }
}

extension ConnectUploadViewController: WebSocketManagerDelegate {
    func newMessage(result: EventData.Socket) {
        guard case let .KeyBundle(deviceId) = result,
            !self.scheduleWorker.isRunning else {
            return
        }
        linkData.deviceId = deviceId
        scheduleWorker.cancel()
        work { (success) in
            guard success else {
                self.scheduleWorker.start()
                return
            }
            self.continueUpload()
        }
    }
}
