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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        socket = SingleWebSocket()
        socket?.delegate = self
        connectUIView.initialLoad(email: "\(signupData.username)\(Constants.domain)")
        DBManager.destroy()
        sendKeysRequest()
    }
    
    func sendKeysRequest(){
        let keyBundle = signupData.buildDataForRequest()["keybundle"] as! [String: Any]
        APIManager.postKeybundle(params: keyBundle, token: signupData.token!){ (responseData) in
            if case let .Error(error) = responseData,
                error.code != .custom {
                return
            }
            guard case let .SuccessString(jwt) = responseData else {
                return
            }
            self.signupData.token = jwt
            self.socket?.connect(jwt: jwt)
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
            print(filepath)
            self.restoreDB(path: filepath, data: data)
        }
    }
    
    func restoreDB(path: String, data: LinkSuccessData) {
        let myAccount = createAccount()
        guard let keyData = Data(base64Encoded: data.key),
            let decryptedKey = SignalHandler.decryptData(keyData, messageType: .preKey, account: myAccount, recipientId: myAccount.username, deviceId: data.deviceId),
            let decryptedPath = AESCipher.streamEncrypt(path: path, outputName: "decrypted-db", keyData: decryptedKey, ivData: nil, operation: kCCDecrypt) else {
            return
        }
        let streamReader = StreamReader(url: URL(fileURLWithPath: decryptedPath), delimeter: "\n", encoding: .utf8, chunkSize: 1024)
        print(try! String(contentsOf: URL(fileURLWithPath: decryptedPath)))
        var dbRows = [[String: Any]]()
        while let line = streamReader?.nextLine() {
            guard let row = Utils.convertToDictionary(text: line) else {
                continue
            }
            dbRows.append(row)
            if dbRows.count >= 30 {
                DBManager.insertBatchRows(rows: dbRows)
                dbRows.removeAll()
            }
        }
        DBManager.insertBatchRows(rows: dbRows)
        connectUIView.handleSuccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.goToMailbox(myAccount.username)
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
        registerFirebaseToken(jwt: myAccount.jwt)
        return myAccount
    }
    
    func goToMailbox(_ activeAccount: String){
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        delegate.createSystemLabels()
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

extension ConnectDeviceViewController: SingleSocketDelegate {
    func newMessage(cmd: Int32, params: [String : Any]?) {
        switch(cmd){
        case Event.Link.success.rawValue:
            guard let address = params?["dataAddress"] as? String,
                let key = params?["key"] as? String else {
                break
            }
            let data = LinkSuccessData(deviceId: 2, key: key, address: address)
            self.handleAddress(data: data)
        default:
            break
        }
    }
}
