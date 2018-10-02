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
    var processingDeviceId : Status = .none
    var checkWorker: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mailboxDelegate = WebSocketManager.sharedInstance.delegate
        WebSocketManager.sharedInstance.delegate = self
        connectUIView.initialLoad(email: "\(myAccount.username)\(Constants.domain)")
        APIManager.linkAccept(randomId: linkData.randomId, token: myAccount.jwt) { (responseData) in
            guard case let .SuccessDictionary(data) = responseData,
                let deviceId = data["deviceId"] as? Int32 else {
                self.showErrorAlert(message: "Unable to accept device")
                return
            }
            self.createDBFile(deviceId: deviceId)
            self.scheduleInterval(deviceId: deviceId)
        }
    }
    
    func scheduleInterval(deviceId: Int32){
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.handleKeyBundleCheck(deviceId: deviceId)
        }
    }
    
    func handleKeyBundleCheck(deviceId: Int32){
        guard self.processingDeviceId == .none else {
            self.scheduleInterval(deviceId: deviceId)
            return
        }
        self.processingDeviceId = .processing
        self.getKeyBundle(deviceId: deviceId, completion: { (success) in
            guard success else {
                self.processingDeviceId = .none
                self.scheduleInterval(deviceId: deviceId)
                return
            }
            self.processingDeviceId = .processed
            self.continueUpload(deviceId: deviceId)
        })
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        WebSocketManager.sharedInstance.delegate = mailboxDelegate
    }
    
    func continueUpload(deviceId: Int32){
        guard let path = self.databasePath,
            processingDeviceId == .processed else {
                return
        }
        uploadDBFile(path: path, deviceId: deviceId)
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
            self.continueUpload(deviceId: deviceId)
        }
    }
    
    func uploadDBFile(path: String, deviceId: Int32){
        guard let inputStream = InputStream.init(fileAtPath: path),
            let fileAttributes = try? FileManager.default.attributesOfItem(atPath: path) else {
                self.showErrorAlert(message: "Unable to open file stream")
                return
        }
        let fileSize = Int(truncating: fileAttributes[.size] as! NSNumber)
        APIManager.uploadLinkDBFile(dbFile: inputStream, size: fileSize, token: myAccount.jwt) { (responseData) in
            guard case let .SuccessString(address) = responseData else {
                self.showErrorAlert(message: "Unable to upload file")
                return
            }
            self.encryptAndSendKeys(address: address, deviceId: deviceId)
        }
    }
    
    func getKeyBundle(deviceId: Int32, completion: @escaping ((Bool) -> Void)){
        APIManager.getKeybundle(deviceId: deviceId, token: myAccount.jwt) { (responseData) in
            guard case let .SuccessDictionary(keys) = responseData else {
                self.showErrorAlert(message: "Unable to retrieve keys")
                completion(false)
                return
            }
            let ex = tryBlock {
                SignalHandler.buildSession(recipientId: self.myAccount.username, deviceId: deviceId, keys: keys, account: self.myAccount)
            }
            guard ex == nil else {
                self.showErrorAlert(message: "Unable to create session")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    func encryptAndSendKeys(address: String, deviceId: Int32){
        var data: Data?
        tryBlock {
            data = SignalHandler.encryptData(data: self.keyData, deviceId: deviceId, recipientId: self.myAccount.username, account: self.myAccount)
        }
        guard let encryptedData = data else {
            self.showErrorAlert(message: "Unable to encrypt key")
            return
        }
        self.sendSuccessData(address: address, deviceId: deviceId, encryptedKey: encryptedData.base64EncodedString())
    }
    
    func sendSuccessData(address: String, deviceId: Int32, encryptedKey: String){
        let params = [
            "deviceId": deviceId,
            "dataAddress": address,
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

extension ConnectUploadViewController: WebSocketManagerDelegate {
    func newMessage(result: EventData.Socket) {
        guard case let .KeyBundle(deviceId) = result else {
            return
        }
        self.handleKeyBundleCheck(deviceId: deviceId)
    }
}
