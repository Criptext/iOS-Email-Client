//
//  ConnectDeviceViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import FirebaseMessaging

class ConnectDeviceViewController: UIViewController{
    
    let PROGRESS_SEND_KEYS = 10.0
    let PROGRESS_SENT_KEYS = 40.0
    let PROGRESS_DOWNLOADING_MAILBOX = 70.0
    let PROGRESS_PROCESSING_FILE = 80.0
    let PROGRESS_COMPLETE = 100.0
    @IBOutlet var connectUIView: ConnectUIView!
    var signupData: SignUpData!
    var socket : SingleWebSocket?
    var scheduleWorker = ScheduleWorker(interval: 10.0, maxRetries: 18)
    var state: ConnectionState = .sendKeys
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    internal struct LinkSuccessData {
        var deviceId: Int32
        var key: String
        var address: String
    }
    
    internal enum ConnectionState{
        case sendKeys
        case waiting
        case downloadDB(LinkSuccessData)
        case unpackDB(Account, String, LinkSuccessData)
        case processDB(Account, String, LinkSuccessData)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        socket = SingleWebSocket()
        socket?.delegate = self
        connectUIView.initialLoad(email: "\(signupData.username)\(Constants.domain)")
        DBManager.destroy()
        scheduleWorker.delegate = self
        connectUIView.goBack = {
            self.goBack()
        }
        
        handleState()
    }
    
    func handleState(){
        switch(state){
        case .sendKeys:
            sendKeysRequest()
        case .waiting:
            break
        case .downloadDB(let successData):
            handleAddress(data: successData)
        case .unpackDB(let account, let path, let successData):
            unpackDB(myAccount: account, path: path, data: successData)
        case .processDB(let account, let path, let successData):
            restoreDB(myAccount: account, path: path, data: successData)
        }
    }
    
    func goBack(){
        socket?.close()
        scheduleWorker.cancel()
        cleanData()
        presentingViewController?.navigationController?.popToRootViewController(animated: false)
        dismiss(animated: true, completion: nil)
    }
    
    func cleanData(){
        if let jwt = signupData.token {
            APIManager.logout(token: jwt, completion: {_ in })
            return
        }
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: "activeAccount") != nil else {
            return
        }
        defaults.removeObject(forKey: "activeAccount")
        DBManager.destroy()
    }
    
    func sendKeysRequest(){
        self.connectUIView.progressChange(value: PROGRESS_SEND_KEYS, message: "Sending Keys", completion: {})
        let keyBundle = signupData.buildDataForRequest()["keybundle"] as! [String: Any]
        APIManager.postKeybundle(params: keyBundle, token: signupData.token!){ (responseData) in
            guard case let .SuccessString(jwt) = responseData else {
                self.presentProcessInterrupted()
                return
            }
            self.state = .waiting
            self.connectUIView.progressChange(value: self.PROGRESS_SENT_KEYS, message: "Waiting for Mailbox", cancel: true, completion: {})
            self.signupData.token = jwt
            self.socket?.connect(jwt: jwt)
            self.scheduleWorker.start()
        }
    }
    
    func handleAddress(data: LinkSuccessData) {
        guard let jwt = signupData.token else {
            self.presentProcessInterrupted()
            return
        }
        APIManager.downloadLinkDBFile(address: data.address, token: jwt, progressCallback: { (progress) in
            self.connectUIView.progressChange(value: self.PROGRESS_SENT_KEYS + (self.PROGRESS_DOWNLOADING_MAILBOX - self.PROGRESS_SENT_KEYS) * progress, message: "Downloading Mailbox", completion: {})
        }) { (responseData) in
            guard case let .SuccessString(filepath) =  responseData else {
                self.presentProcessInterrupted()
                return
            }
            let myAccount = self.createAccount()
            self.state = .unpackDB(myAccount, filepath, data)
            self.handleState()
        }
    }
    
    func unpackDB(myAccount: Account, path: String, data: LinkSuccessData) {
        self.connectUIView.progressChange(value: PROGRESS_PROCESSING_FILE, message: "Decrypting Mailbox", completion: {})
        guard let keyData = Data(base64Encoded: data.key),
            let decryptedKey = SignalHandler.decryptData(keyData, messageType: .preKey, account: myAccount, recipientId: myAccount.username, deviceId: data.deviceId),
            let decryptedPath = AESCipher.streamEncrypt(path: path, outputName: "decrypted-db", keyData: decryptedKey, ivData: nil, operation: kCCDecrypt),
            let decompressedPath = try? AESCipher.compressFile(path: decryptedPath, outputName: "decompressed.db", compress: false) else {
                self.presentProcessInterrupted()
                return
        }
        state = .processDB(myAccount, decompressedPath, data)
        self.handleState()
    }
    
    func restoreDB(myAccount: Account, path: String, data: LinkSuccessData) {
        let queue = DispatchQueue(label: "com.email.loaddb", qos: .background, attributes: .concurrent)
        queue.async {
            let streamReader = StreamReader(url: URL(fileURLWithPath: path), delimeter: "\n", encoding: .utf8, chunkSize: 1024)
            var dbRows = [[String: Any]]()
            var progress = 80
            var maps = DBManager.LinkDBMaps.init(emails: [Int: Int](), contacts: [Int: String]())
            while let line = streamReader?.nextLine() {
                guard let row = Utils.convertToDictionary(text: line) else {
                    continue
                }
                dbRows.append(row)
                if dbRows.count >= 30 {
                    DBManager.insertBatchRows(rows: dbRows, maps: &maps)
                    dbRows.removeAll()
                    if progress < 99 {
                        progress += 1
                    }
                    DispatchQueue.main.async {
                        self.connectUIView.progressChange(value: Double(progress), message: nil, completion: {})
                    }
                }
            }
            DBManager.insertBatchRows(rows: dbRows, maps: &maps)
            DispatchQueue.main.async {
                self.connectUIView.progressChange(value: self.PROGRESS_COMPLETE, message: "Decrypting Mailbox") {
                    self.connectUIView.messageLabel.text = "Mailbox restored successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.goToMailbox(myAccount.username)
                        self.registerFirebaseToken(jwt: myAccount.jwt)
                    }
                }
            }
        }
    }
    
    func createAccount() -> Account {
        let myAccount = Account.create(from: signupData)
        DBManager.store(myAccount)
        let myContact = Contact()
        myContact.displayName = myAccount.name
        myContact.email = "\(myAccount.username)\(Constants.domain)"
        DBManager.store([myContact])
        DBManager.createSystemLabels()
        let defaults = UserDefaults.standard
        defaults.set(myAccount.username, forKey: "activeAccount")
        defaults.set(true, forKey: "welcomeTour")
        return myAccount
    }
    
    func goToMailbox(_ activeAccount: String){
        self.socket?.close()
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let mailboxVC = delegate.initMailboxRootVC(nil, activeAccount)
        var options = UIWindow.TransitionOptions()
        options.direction = .toTop
        options.duration = 0.4
        options.style = .easeOut
        UIApplication.shared.keyWindow?.setRootViewController(mailboxVC, options: options)
    }
    
    func registerFirebaseToken(jwt: String){
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return
        }
        APIManager.registerToken(fcmToken: fcmToken, token: jwt)
    }
    
    func presentProcessInterrupted(){
        let retryPopup = GenericDualAnswerUIPopover()
        retryPopup.initialMessage = "Looks like you're having connection issues. Would you like to retry Mailbox Sync"
        retryPopup.initialTitle = "Sync Interrupted"
        retryPopup.leftOption = "Cancel"
        retryPopup.rightOption = "Retry"
        retryPopup.onResponse = { accept in
            guard accept else {
                self.goBack()
                return
            }
            self.handleState()
        }
        self.presentPopover(popover: retryPopup, height: 235)
    }
}

extension ConnectDeviceViewController: ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void) {
        guard let jwt = signupData.token else {
            print("GOING BACK 1")
            self.goBack()
            return
        }
        APIManager.getLinkData(token: jwt) { (responseData) in
            guard case let .SuccessDictionary(event) = responseData,
                let eventString = event["params"] as? String,
                let eventParams = Utils.convertToDictionary(text: eventString) else {
                completion(false)
                return
            }
            completion(true)
            self.newMessage(cmd: Event.Link.success.rawValue, params: eventParams)
        }
    }
    
    func dangled(){
        let retryPopup = GenericDualAnswerUIPopover()
        retryPopup.initialMessage = "Something has happened that is delaying this process. Do want to continue waiting?"
        retryPopup.initialTitle = "Well, that’s odd…"
        retryPopup.onResponse = { accept in
            guard accept else {
                self.goBack()
                return
            }
            self.scheduleWorker.start()
        }
        self.presentPopover(popover: retryPopup, height: 205)
    }
}

extension ConnectDeviceViewController: SingleSocketDelegate {
    func newMessage(cmd: Int32, params: [String : Any]?) {
        switch(cmd){
        case Event.Link.success.rawValue:
            guard let address = params?["dataAddress"] as? String,
                let key = params?["key"] as? String,
                let deviceId = params?["authorizerId"] as? Int32 else {
                break
            }
            scheduleWorker.cancel()
            let data = LinkSuccessData(deviceId: deviceId, key: key, address: address)
            state = .downloadDB(data)
            handleState()
        default:
            break
        }
    }
}
