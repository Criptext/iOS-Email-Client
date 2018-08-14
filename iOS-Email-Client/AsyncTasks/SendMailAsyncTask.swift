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
    let password: String?
    let subject: String
    let body: String
    var guestEmails: [String: Any]!
    let criptextEmails: [String: Any]!
    let files: [[String: Any]]!
    
    let username: String
    let emailRef: ThreadSafeReference<Object>
    
    init(account: Account, email: Email){
        let files = SendMailAsyncTask.getFilesRequestData(email: email)
        let fileKey = DBManager.getFileKey(emailId: email.key)?.key
        let recipients = SendMailAsyncTask.getRecipientEmails(username: account.username, email: email, files: files, fileKey: fileKey)
        
        self.password = email.password
        self.username = account.username
        self.subject = email.subject
        self.body = email.content
        self.threadId = email.threadId.isEmpty || email.threadId == email.key.description ? nil : email.threadId
        self.guestEmails = recipients.0
        self.criptextEmails = recipients.1
        self.files = files
        self.emailRef = DBManager.getReference(email)
        self.fileKey = fileKey
    }
    
    private class func getFilesRequestData(email: Email) -> [[String: Any]]{
        return email.files.map { (file) -> [String: Any] in
            return ["token": file.token,
                    "name": file.name,
                    "size": file.size,
                    "mimeType": file.mimeType]
        }
    }
    
    private class func getRecipientEmails(username: String, email: Email, files: [[String: Any]], fileKey: String?) -> ([String: Any], [String: Any]) {
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
        let body = email.content + SendMailAsyncTask.buildAttachmentsHtml(attachments: files, keys: fileKey)
        if(!toArray.isEmpty || !ccArray.isEmpty || !bccArray.isEmpty){
            guestEmails["to"] = toArray
            guestEmails["cc"] = ccArray
            guestEmails["bcc"] = bccArray
            guestEmails["body"] = body
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
            
            if let password = self.password {
                let dummySessionData = self.buildDummySession(password: password, myAccount: myAccount)
                self.guestEmails["body"] = dummySessionData.body
                self.guestEmails["session"] = dummySessionData.session
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
    
    private func buildDummySession(password: String, myAccount: Account) -> SendEmailData.GuestContent{
        let dummy = Dummy(recipientId: password)
        let keyBundle = dummy.getKeyBundle()
        let body = encryptDummyBody(keys: keyBundle, myAccount: myAccount)
        var session = dummy.getSessionBundle()
        if let fileKey = self.fileKey {
            session["fileKey"] = fileKey
        }
        let aesSalt = AESCipher.generateRandomBytes(length: 8)
        let aesKey = AESCipher.generateKey(password: password, saltData: aesSalt)!
        let aesIv = AESCipher.generateRandomBytes(length: 16)
        let sessionString = Utils.convertToJSONString(dictionary: session)!
        let encryptedSession = AESCipher.encrypt(data: sessionString.data(using: .utf8)!, keyData: aesKey, ivData: aesIv, operation: kCCEncrypt)!
        var encryptedGuest = Data()
        encryptedGuest.append(aesSalt)
        encryptedGuest.append(aesIv)
        encryptedGuest.append(encryptedSession)
        return SendEmailData.GuestContent.init(body: body, session: encryptedGuest.base64EncodedString())
    }
    
    private func encryptDummyBody(keys: [String: Any], myAccount: Account) -> String {
        let recipientId = keys["recipientId"] as! String
        let deviceId = keys["deviceId"] as! Int32
        SignalHandler.buildSession(recipientId: recipientId, deviceId: deviceId, keys: keys, account: myAccount)
        let message = SignalHandler.encryptMessage(body: self.body, deviceId: deviceId, recipientId: recipientId, account: myAccount)
        return message.0
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
    
    private class func buildAttachmentsHtml(attachments: [[String: Any]], keys: String?) -> String {
        guard !attachments.isEmpty,
            let fileKeys = keys else {
            return ""
        }
        return "<br/><div>" + attachments.reduce("") { (result, attachment) -> String in
            let params = "\(attachment["token"] as! String):\(fileKeys)"
            let encodedParams = params.data(using: .utf8)!.base64EncodedString()
            let size = attachment["size"] as! Int
            let sizeString = File.prettyPrintSize(size: Float(size))
            return result + buildAttachmentHtml(name: attachment["name"] as! String, mimeType: attachment["mimeType"] as! String, size: sizeString, encodedParams: encodedParams)
        } + "</div>"
    }
    
    private class func buildAttachmentHtml(name: String, mimeType: String, size: String, encodedParams: String) -> String{
        return """
        <div style="margin-top: 6px; float: left;">
            <a style="cursor: pointer; text-decoration: none;" href="http://services.criptext.com/downloader/\(encodedParams)?e=1">
                <div style="align-items: center; border: 1px solid #e7e5e5; border-radius: 6px; display: flex; height: 20px; margin-right: 20px; padding: 10px; position: relative; width: 236px;">
                    <div style="position: relative;">
                        <div style="align-items: center; border-radius: 4px; display: flex; height: 22px; width: 22px;">
                            <img src="https://cdn.criptext.com/External-Email/imgs/\(Utils.getExternalImage(mimeType)).png" style="height: 100%; width: 100%;"/>
                        </div>
                    </div>
                    <div style="padding-top: 1px; display: flex; flex-grow: 1; height: 100%; margin-left: 10px; width: calc(100% - 32px);">
                        <span style="color: black; padding-top: 1px; width: 160px; flex-grow: 1; font-size: 14px; font-weight: 700; overflow: hidden; padding-right: 5px; text-overflow: ellipsis; white-space: nowrap;">\(name)</span>
                        <span style="color: #9b9b9b; flex-grow: 0; font-size: 13px; white-space: nowrap; line-height: 21px;">\(size)</span>
                    </div>
                </div>
            </a>
        </div>
        """
    }
    
}
