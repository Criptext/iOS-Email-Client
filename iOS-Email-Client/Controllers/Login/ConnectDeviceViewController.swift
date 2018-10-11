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
    
    @IBOutlet var connectUIView: ConnectUIView!
    var signupData: SignUpData!
    var socket : SingleWebSocket?
    var scheduleWorker = ScheduleWorker(interval: 5.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        socket = SingleWebSocket()
        socket?.delegate = self
        connectUIView.initialLoad(email: "\(signupData.username)\(Constants.domain)")
        DBManager.destroy()
        sendKeysRequest()
        scheduleWorker.delegate = self
        connectUIView.goBack = {
            self.socket?.close()
            self.scheduleWorker.cancel()
            self.presentingViewController?.navigationController?.popToRootViewController(animated: false)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func sendKeysRequest(){
        connectUIView.goBackButton.isHidden = true
        connectUIView.messageLabel.text = "Generating Keys..."
        let keyBundle = signupData.buildDataForRequest()["keybundle"] as! [String: Any]
        APIManager.postKeybundle(params: keyBundle, token: signupData.token!){ (responseData) in
            if case let .Error(error) = responseData,
                error.code != .custom {
                return
            }
            guard case let .SuccessString(jwt) = responseData else {
                return
            }
            self.connectUIView.goBackButton.isHidden = false
            self.connectUIView.messageLabel.text = "Waiting for emails..."
            self.signupData.token = jwt
            self.socket?.connect(jwt: jwt)
            self.scheduleWorker.start()
        }
    }
    
    func handleAddress(data: LinkSuccessData) {
        guard let jwt = signupData.token else {
            return
        }
        APIManager.downloadLinkDBFile(address: data.address, token: jwt) { (responseData) in
            guard case let .SuccessString(filepath) =  responseData else {
                return
            }
            self.restoreDB(path: filepath, data: data)
        }
    }
    
    func restoreDB(path: String, data: LinkSuccessData) {
        let myAccount = createAccount()
        guard let keyData = Data(base64Encoded: data.key),
            let decryptedKey = SignalHandler.decryptData(keyData, messageType: .preKey, account: myAccount, recipientId: myAccount.username, deviceId: data.deviceId),
            let decryptedPath = AESCipher.streamEncrypt(path: path, outputName: "decrypted-db", keyData: decryptedKey, ivData: nil, operation: kCCDecrypt),
            let decompressedPath = try? AESCipher.compressFile(path: decryptedPath, outputName: "decompressed.db", compress: false)else {
                print("YA VALIO MADRES")
                return
        }
        self.connectUIView.goBackButton.isHidden = true
        self.connectUIView.messageLabel.text = "Restoring emails..."
        let queue = DispatchQueue(label: "com.email.loaddb", qos: .background, attributes: .concurrent)
        queue.async {
            DBManager.createSystemLabels()
            print(decompressedPath)
            let streamReader = StreamReader(url: URL(fileURLWithPath: decompressedPath), delimeter: "\n", encoding: .utf8, chunkSize: 1024)
            var dbRows = [[String: Any]]()
            var maps = DBManager.LinkDBMaps.init(emails: [Int: Int](), contacts: [Int: String]())
            while let line = streamReader?.nextLine() {
                guard let row = Utils.convertToDictionary(text: line) else {
                    continue
                }
                dbRows.append(row)
                if dbRows.count >= 30 {
                    DBManager.insertBatchRows(rows: dbRows, maps: &maps)
                    dbRows.removeAll()
                }
            }
            DBManager.insertBatchRows(rows: dbRows, maps: &maps)
            DispatchQueue.main.async {
                self.connectUIView.messageLabel.text = "Mailbox restored successfully!"
                self.connectUIView.handleSuccess()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.goToMailbox(myAccount.username)
                }
            }
        }
    }
    
    func createAccount() -> Account {
        let myAccount = Account()
        myAccount.username = signupData.username
        myAccount.name = signupData.fullname
        myAccount.jwt = signupData.token!
        myAccount.regId = signupData.getRegId()
        myAccount.identityB64 = signupData.getIdentityKeyPairB64() ?? ""
        myAccount.deviceId = signupData.deviceId
        DBManager.store(myAccount)
        let myContact = Contact()
        myContact.displayName = myAccount.name
        myContact.email = "\(myAccount.username)\(Constants.domain)"
        DBManager.store([myContact])
        let defaults = UserDefaults.standard
        defaults.set(myAccount.username, forKey: "activeAccount")
        defaults.set(true, forKey: "welcomeTour")
        registerFirebaseToken(jwt: myAccount.jwt)
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
    
    internal struct LinkSuccessData {
        var deviceId: Int32
        var key: String
        var address: String
    }
}

extension ConnectDeviceViewController: ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void) {
        guard let jwt = signupData.token else {
            return
        }
        APIManager.getLinkData(token: jwt) { (responseData) in
            guard case let .SuccessDictionary(event) = responseData else {
                completion(false)
                return
            }
            completion(true)
            self.newMessage(cmd: Event.Link.success.rawValue, params: event)
        }
    }
}

extension ConnectDeviceViewController: SingleSocketDelegate {
    func newMessage(cmd: Int32, params: [String : Any]?) {
        switch(cmd){
        case Event.Link.success.rawValue:
            guard let eventString = params?["params"] as? String,
                let eventParams = Utils.convertToDictionary(text: eventString),
                let address = eventParams["dataAddress"] as? String,
                let key = eventParams["key"] as? String,
                let deviceId = eventParams["authorizerId"] as? Int32 else {
                break
            }
            self.connectUIView.goBackButton.isHidden = true
            self.connectUIView.messageLabel.text = "Retrieving emails..."
            scheduleWorker.cancel()
            let data = LinkSuccessData(deviceId: deviceId, key: key, address: address)
            self.handleAddress(data: data)
        default:
            break
        }
    }
}
