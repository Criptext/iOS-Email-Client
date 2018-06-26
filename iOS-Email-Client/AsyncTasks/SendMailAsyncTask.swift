//
//  SendMailAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 6/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework
import RealmSwift

class SendMailAsyncTask {
    
    let threadId: String?
    let subject: String
    let body: String
    let guestEmails: [String: Any]
    let criptextEmails: [String: Any]
    let files: [[String: Any]]
    
    let username: String
    let emailRef: ThreadSafeReference<Object>
    
    init(account: Account, email: Email, threadId: String?, subject: String, body: String, guestEmails: [String: Any], criptextEmails: [String: Any], files: [[String: Any]]){
        self.subject = subject
        self.body = body
        self.guestEmails = guestEmails
        self.criptextEmails = criptextEmails
        self.files = files
        self.threadId = threadId
        
        self.username = account.username
        self.emailRef = DBManager.getReference(email)
    }
    
    func start(completion: @escaping ((Error?, Any?) -> Void)){
        let queue = DispatchQueue(label: "com.email.sendmail", qos: .background, attributes: .concurrent)
        queue.async {
            self.getSessionAndEncrypt(queue: queue, completion: completion)
        }
    }
    
    private func getSessionAndEncrypt(queue: DispatchQueue, completion: @escaping ((Error?, Any?) -> Void)){
        let myAccount = DBManager.getAccountByUsername(self.username)!
        var recipients = [String]()
        var knownAddresses = [String: [Int32]]()
        var criptextEmailsData = [[String: Any]]()
        for (recipientId, type) in criptextEmails {
            let recipientSessions = DBManager.getSessionRecords(recipientId: recipientId)
            let deviceIds = recipientSessions.map { $0.deviceId }
            recipients.append(recipientId)
            for deviceId in deviceIds {
                let message = SignalHandler.encryptMessage(body: body, deviceId: deviceId, recipientId: recipientId, account: myAccount)
                let criptextEmail = ["recipientId": recipientId,
                                     "deviceId": deviceId,
                                     "type": type,
                                     "body": message.0,
                                     "messageType": message.1.rawValue] as [String: Any]
                criptextEmailsData.append(criptextEmail)
            }
            knownAddresses[recipientId] = deviceIds
        }
        
        let params = [
            "recipients": recipients,
            "knownAddresses": knownAddresses
            ] as [String : Any]
        
        APIManager.getKeysRequest(params, token: myAccount.jwt, queue: queue) { (err, response) in
            let myAccount = DBManager.getAccountByUsername(self.username)!
            guard let keysArray = response as? [[String: Any]] else {
                self.handleResponseInMainThread {
                    completion(err, nil)
                }
                return
            }
            for keys in keysArray {
                let recipientId = keys["recipientId"] as! String
                let deviceId = keys["deviceId"] as! Int32
                let type = self.criptextEmails[recipientId] as! String
                
                SignalHandler.buildSession(recipientId: recipientId, deviceId: deviceId, keys: keys, account: myAccount)
                let message = SignalHandler.encryptMessage(body: self.body, deviceId: deviceId, recipientId: recipientId, account: myAccount)
                let criptextEmail = ["recipientId": recipientId,
                                     "deviceId": deviceId,
                                     "type": type,
                                     "body": message.0,
                                     "messageType": message.1.rawValue] as [String: Any]
                criptextEmailsData.append(criptextEmail)
            }
            self.sendMail(myAccount: myAccount, criptextEmails: criptextEmailsData, queue: queue, completion: completion)
        }
    }
    
    private func sendMail(myAccount: Account, criptextEmails: [Any], queue: DispatchQueue, completion: @escaping ((Error?, Any?) -> Void)){
        let myAccount = DBManager.getAccountByUsername(self.username)!
        var requestParams = [
            "subject": subject,
            "criptextEmails": criptextEmails] as [String : Any]
        if (!files.isEmpty) {
            requestParams["files"] = files
        }
        if let thread = self.threadId {
            requestParams["threadId"] = thread
        }
        APIManager.postMailRequest(requestParams, token: myAccount.jwt, queue: queue) { (error, data) in
            if let error = error {
                self.handleResponseInMainThread {
                    completion(error, nil)
                }
                return
            }
            self.updateEmailData(data)
            self.handleResponseInMainThread {
                completion(nil, data)
            }
        }
    }
    
    func setEmailAsFailed(){
        guard let email = DBManager.getObject(emailRef) as? Email else {
            return
        }
        DBManager.updateEmail(email, status: .fail)
    }
    
    func updateEmailData(_ data : Any?){
        guard let email = DBManager.getObject(emailRef) as? Email else {
            return
        }
        let keysArray = data as! [String: Any]
        let key = (keysArray["metadataKey"] as! Int32).description
        let messageId = keysArray["messageId"] as! String
        let threadId = keysArray["threadId"] as! String
        DBManager.updateEmail(email, key: key, messageId: messageId, threadId: threadId)
        DBManager.updateEmail(email, status: .delivered)
        updateFiles(emailId: key)
    }
    
    func updateFiles(emailId: String){
        for file in files {
            guard let filetoken = file["token"] as? String else {
                continue
            }
            DBManager.update(filetoken: filetoken, emailId: emailId)
        }
    }
    
    private func handleResponseInMainThread(completionHandler: @escaping () -> Void){
        DispatchQueue.main.async {
            completionHandler()
        }
    }
    
}
