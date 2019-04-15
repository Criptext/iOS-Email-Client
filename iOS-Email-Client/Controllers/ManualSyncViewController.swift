//
//  ManualSyncViewController.swift
//  iOS-Email-Client
//
//  Created by Allisson on 1/2/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class ManualSyncViewController: UIViewController{
    
    let PROGRESS_DOWNLOADING_MAILBOX = 70.0
    let PROGRESS_PROCESSING_FILE = 80.0
    let PROGRESS_COMPLETE = 100.0
    @IBOutlet var connectUIView: ConnectUIView!
    var acceptData: AcceptData!
    var socket : SingleWebSocket?
    weak var previousWebsocketDelegate: WebSocketManagerDelegate?
    var scheduleWorker = ScheduleWorker(interval: 10.0, maxRetries: 18)
    weak var myAccount: Account!
    var state: ConnectionState = .waiting
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    internal struct LinkSuccessData {
        var key: String
        var address: String
    }
    
    internal enum ConnectionState{
        case waiting
        case downloadDB(LinkSuccessData)
        case unpackDB(Account, String, LinkSuccessData)
        case processDB(Account, String, LinkSuccessData)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.previousWebsocketDelegate = WebSocketManager.sharedInstance.delegate
        WebSocketManager.sharedInstance.delegate = nil
        socket = SingleWebSocket()
        socket?.delegate = self
        connectUIView.initialLoad(email: "\(myAccount.username)\(Constants.domain)")
        self.applyTheme()
        scheduleWorker.delegate = self
        connectUIView.goBack = {
            self.goBack()
        }
        if let linkAcceptData = acceptData {
            self.connectUIView.setDeviceIcons(leftType: Device.Kind(rawValue: linkAcceptData.authorizerType) ?? .pc, rightType: .current)
        }
        self.connectUIView.progressChange(value: 0, message: String.localize("WAITING_MAIL"), cancel: true, completion: {})
        self.socket?.connect(jwt: myAccount.jwt)
        self.scheduleWorker.start()
        handleState()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        connectUIView.applyTheme()
        self.view.backgroundColor = theme.overallBackground
    }
    
    func handleState(){
        switch(state){
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
        WebSocketManager.sharedInstance.delegate = previousWebsocketDelegate
        previousWebsocketDelegate = nil
        presentingViewController?.navigationController?.popToRootViewController(animated: false)
        dismiss(animated: true, completion: nil)
    }
    
    func handleAddress(data: LinkSuccessData) {
        APIManager.downloadLinkDBFile(address: data.address, token: myAccount.jwt, progressCallback: { (progress) in
            self.connectUIView.progressChange(value: self.PROGRESS_DOWNLOADING_MAILBOX * progress, message: String.localize("DOWNLOADING_MAIL"), completion: {})
        }) { (responseData) in
            guard case let .SuccessString(filepath) =  responseData else {
                self.presentProcessInterrupted()
                return
            }
            self.state = .unpackDB(self.myAccount, filepath, data)
            self.handleState()
        }
    }
    
    func unpackDB(myAccount: Account, path: String, data: LinkSuccessData) {
        self.connectUIView.progressChange(value: PROGRESS_PROCESSING_FILE, message: String.localize("DECRYPTING_MAIL"), completion: {})
        guard let linkAcceptData = self.acceptData,
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
        DBManager.clearMailbox(account: myAccount)
        FileUtils.deleteAccountDirectory(account: myAccount)
        DBManager.clearMailbox(account: myAccount)
        
        let restoreTask = RestoreDBAsyncTask(path: path, username: myAccount.username, initialProgress: 80)
        restoreTask.start(progressHandler: { (progress) in
            self.connectUIView.progressChange(value: Double(progress), message: nil, completion: {})
        }) {
            self.restoreSuccess()
        }
        
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
                
            }
        }
    }
    
    func restoreSuccess() {
        self.connectUIView.progressChange(value: self.PROGRESS_COMPLETE, message: String.localize("DECRYPTING_MAIL")) {
            self.connectUIView.messageLabel.text = String.localize("MAIL_RESTORED")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.dismissToRoot()
            }
        }
    }
    
    func dismissToRoot() {
        WebSocketManager.sharedInstance.delegate = previousWebsocketDelegate
        previousWebsocketDelegate = nil
        guard let inboxVC = (UIApplication.shared.delegate as? AppDelegate)?.getInboxVC() else {
            return
        }
        inboxVC.dismiss(animated: true) {
            inboxVC.refreshThreadRows()
            inboxVC.showSnackbar(String.localize("SYNC_COMPLETED"), attributedText: nil, buttons: "", permanent: false)
        }
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

extension ManualSyncViewController: ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void) {
        APIManager.getLinkData(token: myAccount.jwt) { (responseData) in
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

extension ManualSyncViewController: SingleSocketDelegate {
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
