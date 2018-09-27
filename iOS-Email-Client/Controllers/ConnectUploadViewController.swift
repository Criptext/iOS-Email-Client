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
    
    @IBOutlet var connectUIView: ConnectUIView!
    var linkData: LinkData!
    var myAccount: Account!
    var mailboxDelegate: WebSocketManagerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mailboxDelegate = WebSocketManager.sharedInstance.delegate
        WebSocketManager.sharedInstance.delegate = self
        connectUIView.initialLoad(email: "\(myAccount.username)\(Constants.domain)")
        APIManager.linkAccept(randomId: linkData.randomId, token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                self.showErrorAlert(message: "Unable to accept device")
                return
            }
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        WebSocketManager.sharedInstance.delegate = mailboxDelegate
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
            self.uploadDBFile(path: outputPath, deviceId: deviceId)
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
    
    func encryptAndSendKeys(address: String, deviceId: Int32){
        let queue = DispatchQueue.main
        let params = [
            "recipients": [myAccount.username],
            "knownAddresses": [
                myAccount.username: [myAccount.deviceId]
            ]
        ] as [String: Any]
        APIManager.getKeysRequest(params, token: myAccount.jwt, queue: queue) { (responseData) in
            guard case let .SuccessArray(keysArray) = responseData,
                let desiredKeys = keysArray.first(where: {($0["deviceId"] as! Int) == deviceId}) else {
                    self.showErrorAlert(message: "Unable to retrieve keys")
                return
            }
            var data: Data?
            tryBlock {
                SignalHandler.buildSession(recipientId: self.myAccount.username, deviceId: deviceId, keys: desiredKeys, account: self.myAccount)
                data = SignalHandler.encryptData(data: self.keyData, deviceId: deviceId, recipientId: self.myAccount.username, account: self.myAccount)
            }
            guard let encryptedData = data else {
                self.showErrorAlert(message: "Unable to encrypt key")
                return
            }
            self.sendSuccessData(address: address, deviceId: deviceId, encryptedKey: encryptedData.base64EncodedString())
        }
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
        createDBFile(deviceId: deviceId)
    }
}
