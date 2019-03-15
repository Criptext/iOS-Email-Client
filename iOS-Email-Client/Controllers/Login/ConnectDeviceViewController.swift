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
    var multipleAccount = false
    var account: Account?
    var bundle: CRBundle?
    var linkData: LoginDeviceViewController.LinkAccept?
    var socket : SingleWebSocket?
    var scheduleWorker = ScheduleWorker(interval: 10.0, maxRetries: 18)
    var state: ConnectionState = .sendKeys
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    internal struct LinkSuccessData {
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
        scheduleWorker.delegate = self
        connectUIView.goBack = {
            self.goBack()
        }
        if let linkAcceptData = linkData {
            self.connectUIView.setDeviceIcons(leftType: Device.Kind(rawValue: linkAcceptData.authorizerType)!, rightType: .current)
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
        guard let myAccount = account else {
            return
        }
        FileUtils.deleteAccountDirectory(account: myAccount)
        DBManager.clearMailbox(account: myAccount)
        DBManager.signout(account: myAccount)
    }
    
    func createAccount() -> (Account, [String: Any]) {
        if let myKeys = self.bundle?.publicKeys,
            let myAccount = self.account {
            return(myAccount, myKeys)
        }
        let account = SignUpData.createAccount(from: self.signupData)
        DBManager.store(account)
        
        let bundle = CRBundle(account: account)
        let keys = bundle.generateKeys()
        self.account = account
        self.bundle = bundle
        return (account, keys)
    }
    
    func sendKeysRequest(){
        self.connectUIView.progressChange(value: PROGRESS_SEND_KEYS, message: String.localize("SENDING_KEYS"), completion: {})
        let accountData = createAccount()
        APIManager.postKeybundle(params: accountData.1, token: signupData.token!){ (responseData) in
            guard case let .SuccessDictionary(tokens) = responseData,
                let jwt = tokens["token"] as? String,
                let refreshToken = tokens["refreshToken"] as? String else {
                    self.presentProcessInterrupted()
                    return
            }
            self.state = .waiting
            self.connectUIView.progressChange(value: self.PROGRESS_SENT_KEYS, message: String.localize("WAITING_MAIL"), cancel: true, completion: {})
            self.signupData.token = jwt
            self.signupData.refreshToken = refreshToken
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
            self.connectUIView.progressChange(value: self.PROGRESS_SENT_KEYS + (self.PROGRESS_DOWNLOADING_MAILBOX - self.PROGRESS_SENT_KEYS) * progress, message: String.localize("DOWNLOADING_MAIL"), completion: {})
        }) { (responseData) in
            guard case let .SuccessString(filepath) =  responseData else {
                self.presentProcessInterrupted()
                return
            }
            self.updateAccount()
            self.state = .unpackDB(self.account!, filepath, data)
            self.handleState()
        }
    }
    
    func unpackDB(myAccount: Account, path: String, data: LinkSuccessData) {
        self.connectUIView.progressChange(value: PROGRESS_PROCESSING_FILE, message: String.localize("DECRYPTING_MAIL"), completion: {})
        guard let linkAcceptData = self.linkData,
            let keyData = Data(base64Encoded: data.key),
            let decryptedKey = SignalHandler.decryptData(keyData, messageType: .preKey, account: myAccount, recipientId: myAccount.username, deviceId: linkAcceptData.authorizerId),
            let decryptedPath = AESCipher.streamEncrypt(path: path, outputName: StaticFile.decryptedDB.name, keyData: decryptedKey, ivData: nil, operation: kCCDecrypt),
            let decompressedPath = try? AESCipher.compressFile(path: decryptedPath, outputName: StaticFile.unzippedDB.name, compress: false) else {
                self.presentProcessInterrupted()
                return
        }
        CriptextFileManager.deleteFile(path: path)
        CriptextFileManager.deleteFile(path: decryptedPath)
        state = .processDB(myAccount, decompressedPath, data)
        self.handleState()
    }
    
    func restoreDB(myAccount: Account, path: String, data: LinkSuccessData) {
        let queue = DispatchQueue(label: "com.email.loaddb", qos: .background, attributes: .concurrent)
        let username = myAccount.username
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
                    DBManager.insertBatchRows(rows: dbRows, maps: &maps, username: username)
                    dbRows.removeAll()
                    if progress < 99 {
                        progress += 1
                    }
                    DispatchQueue.main.async {
                        self.connectUIView.progressChange(value: Double(progress), message: nil, completion: {})
                    }
                }
            }
            DBManager.insertBatchRows(rows: dbRows, maps: &maps, username: username)
            CriptextFileManager.deleteFile(path: path)
            DispatchQueue.main.async {
                self.connectUIView.progressChange(value: self.PROGRESS_COMPLETE, message: String.localize("DECRYPTING_MAIL")) {
                    self.connectUIView.messageLabel.text = String.localize("MAIL_RESTORED")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if self.multipleAccount {
                            self.goBackToMailbox(account: myAccount)
                        } else {
                            self.goToMailbox(myAccount.username)
                        }
                        self.registerFirebaseToken(jwt: myAccount.jwt)
                    }
                }
            }
        }
    }
    
    func updateAccount() {
        guard let myAccount = self.account,
            let myBundle = self.bundle,
            let jwt = signupData.token,
            let refreshToken = signupData.refreshToken,
            let identityB64 = myBundle.store.identityKeyStore.getIdentityKeyPairB64() else {
                return
        }
        let regId = myBundle.store.identityKeyStore.getRegId()
        DBManager.update(account: myAccount, jwt: jwt, refreshToken: refreshToken, regId: regId, identityB64: identityB64)
        let myContact = Contact()
        myContact.displayName = myAccount.name
        myContact.email = "\(myAccount.username)\(Constants.domain)"
        DBManager.store([myContact], account: myAccount)
        DBManager.createSystemLabels()
        let defaults = CriptextDefaults()
        defaults.activeAccount = myAccount.username
        defaults.welcomeTour = true
    }
    
    func goBackToMailbox(account: Account) {
        self.account = nil
        self.socket?.close()
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            self.dismiss(animated: true)
            return
        }
        delegate.swapAccount(account: account)
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
        retryPopup.initialMessage = String.localize("SYNC_CONNECTION_ISSUES")
        retryPopup.initialTitle = String.localize("SYNC_INTERRUPTED")
        retryPopup.leftOption = String.localize("CANCEL")
        retryPopup.rightOption = String.localize("RETRY")
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
        retryPopup.initialMessage = String.localize("DELAYED_PROCESS_RETRY")
        retryPopup.initialTitle = String.localize("ODD")
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
        guard case .waiting = state else {
            return
        }
        switch(cmd){
        case Event.Link.success.rawValue:
            guard let address = params?["dataAddress"] as? String,
                let key = params?["key"] as? String else {
                break
            }
            scheduleWorker.cancel()
            let data = LinkSuccessData(key: key, address: address)
            state = .downloadDB(data)
            handleState()
        default:
            break
        }
    }
}
