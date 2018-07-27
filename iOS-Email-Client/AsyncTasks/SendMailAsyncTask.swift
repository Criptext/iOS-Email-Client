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
    
    let fileKey: String?
    let threadId: String?
    let subject: String
    let body: String
    let guestEmails: [String: Any]!
    let criptextEmails: [String: Any]!
    let files: [[String: Any]]!
    
    let username: String
    let emailRef: ThreadSafeReference<Object>
    
    init(account: Account, email: Email){
        let recipients = SendMailAsyncTask.getRecipientEmails(username: account.username, email: email)
        
        self.username = account.username
        self.subject = email.subject
        self.body = email.content
        self.threadId = email.threadId.isEmpty || email.threadId == email.key.description ? nil : email.threadId
        self.guestEmails = recipients.0
        self.criptextEmails = recipients.1
        self.files = SendMailAsyncTask.getFilesRequestData(email: email)
        self.emailRef = DBManager.getReference(email)
        self.fileKey = DBManager.getFileKey(emailId: email.key)?.key
    }
    
    private class func getFilesRequestData(email: Email) -> [[String: Any]]{
        return email.files.map { (file) -> [String: Any] in
            return ["token": file.token,
                    "name": file.name,
                    "size": file.size,
                    "mimeType": file.mimeType]
        }
    }
    
    private class func getRecipientEmails(username: String, email: Email) -> ([String: Any], [String: Any]) {
        var criptextEmails = [username: "peer"] as [String: String]
        var toArray = [String]()
        var ccArray = [String]()
        var bccArray = [String]()
        
        let toContacts = email.getContacts(type: .to)
        for contact in toContacts {
            if(contact.email.contains(Constants.domain)){
                criptextEmails[String(contact.email.split(separator: "@")[0])] = "to"
            } else {
                toArray.append(contact.email)
            }
        }
        
        let ccContacts = email.getContacts(type: .cc)
        for contact in ccContacts {
            if(contact.email.contains(Constants.domain)){
                criptextEmails[String(contact.email.split(separator: "@")[0])] = "cc"
            } else {
                ccArray.append(contact.email)
            }
        }
        
        let bccContacts = email.getContacts(type: .bcc)
        for contact in bccContacts {
            if(contact.email.contains(Constants.domain)){
                criptextEmails[String(contact.email.split(separator: "@")[0])] = "bcc"
            } else {
                bccArray.append(contact.email)
            }
        }
        
        var guestEmails = [String : Any]()
        
        if(!toArray.isEmpty){
            guestEmails["to"] = toArray
            guestEmails["body"] = (email.secure ? "secure email" : email.content)
        }
        if(!ccArray.isEmpty){
            guestEmails["cc"] = ccArray
            guestEmails["body"] = (email.secure ? "secure email" : email.content)
        }
        if(!bccArray.isEmpty){
            guestEmails["bcc"] = bccArray
            guestEmails["body"] = (email.secure ? "secure email" : email.content)
        }
        return (guestEmails, criptextEmails)
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
            let type = type as! String
            let recipientSessions = DBManager.getSessionRecords(recipientId: recipientId)
            let deviceIds = recipientSessions.map { $0.deviceId }
            recipients.append(recipientId)
            for deviceId in deviceIds {
                guard !(type == "peer" && recipientId == myAccount.username && deviceId == myAccount.deviceId) else {
                    continue
                }
                let criptextEmail = buildCriptextEmail(recipientId: recipientId, deviceId: deviceId, type: type, myAccount: myAccount)
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
                guard !(type == "peer" && recipientId == myAccount.username && deviceId == myAccount.deviceId) else {
                    continue
                }
                let criptextEmail = self.buildCriptextEmail(recipientId: recipientId, deviceId: deviceId, type: type, myAccount: myAccount)
                criptextEmailsData.append(criptextEmail)
            }
            self.sendMail(myAccount: myAccount, criptextEmails: criptextEmailsData, queue: queue, completion: completion)
        }
    }
    
    private func buildCriptextEmail(recipientId: String, deviceId: Int32, type: String, myAccount: Account) -> [String: Any]{
        let message = SignalHandler.encryptMessage(body: self.body, deviceId: deviceId, recipientId: recipientId, account: myAccount)
        var criptextEmail = ["recipientId": recipientId,
                             "deviceId": deviceId,
                             "type": type,
                             "body": message.0,
                             "messageType": message.1.rawValue] as [String: Any]
        if !self.files.isEmpty,
            let fileKey = self.fileKey {
            criptextEmail["fileKey"] = SignalHandler.encryptMessage(body: fileKey, deviceId: deviceId, recipientId: recipientId, account: myAccount).0
        }
        return criptextEmail
    }
    
    private func sendMail(myAccount: Account, criptextEmails: [Any], queue: DispatchQueue, completion: @escaping ((Error?, Any?) -> Void)){
        let myAccount = DBManager.getAccountByUsername(self.username)!
        var requestParams = ["subject": subject] as [String : Any]
        if(!criptextEmails.isEmpty){
            requestParams["criptextEmails"] = criptextEmails
        }
        if(!guestEmails.isEmpty){
            requestParams["guestEmail"] = guestEmails
        }
        if (!files.isEmpty) {
            requestParams["files"] = files
        }
        if let thread = self.threadId {
            requestParams["threadId"] = thread
        }
        APIManager.postMailRequest(requestParams, token: myAccount.jwt, queue: queue) { (error, data) in
            if let error = error {
                self.handleResponseInMainThread {
                    self.setEmailAsFailed()
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
        let key = keysArray["metadataKey"] as! Int
        let messageId = keysArray["messageId"] as! String
        let threadId = keysArray["threadId"] as! String
        DBManager.updateEmail(email, key: key, messageId: messageId, threadId: threadId)
        DBManager.updateEmail(email, status: .sent)
        updateFiles(emailId: key)
    }
    
    func updateFiles(emailId: Int){
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
