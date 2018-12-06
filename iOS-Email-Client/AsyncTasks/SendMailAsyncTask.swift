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
    var guestEmails: [String: Any]
    let criptextEmails: [String: Any]
    var files: [[String: Any]]
    let duplicates: [String]
    let password: String?
    let isSecure: Bool
    let username: String
    let emailKey: Int
    let emailRef: ThreadSafeReference<Object>
    
    init(account: Account, email: Email, password: String?){
        let fileParams = SendMailAsyncTask.getFilesRequestData(email: email)
        let files = fileParams.0
        let duplicates = fileParams.1
        let fileKey = SharedDB.getFileKey(emailId: email.key)?.key
        let recipients = SendMailAsyncTask.getRecipientEmails(username: account.username, email: email, files: files, fileKey: fileKey)
        
        self.username = account.username
        self.emailKey = email.key
        self.subject = email.subject
        self.body = email.content
        self.isSecure = email.secure
        self.threadId = email.threadId.isEmpty || email.threadId == email.key.description ? nil : email.threadId
        self.guestEmails = recipients.0
        self.criptextEmails = recipients.1
        self.files = files
        self.duplicates = duplicates
        self.emailRef = SharedDB.getReference(email)
        self.fileKey = fileKey
        
        self.password = password
    }
    
    private class func getFilesRequestData(email: Email) -> ([[String: Any]], [String]){
        var files = [[String: Any]]()
        var duplicates = [String]()
        for file in email.files {
            if (file.shouldDuplicate) {
                guard let token = file.originalToken else {
                    continue
                }
                duplicates.append(token)
            } else {
                let fileparams = ["token": file.token,
                                  "name": file.name,
                                  "size": file.size,
                                  "mimeType": file.mimeType] as [String : Any]
                files.append(fileparams)
            }
        }
        return (files, duplicates)
    }
    
    private class func getRecipientEmails(username: String, email: Email, files: [[String: Any]], fileKey: String?) -> ([String: Any], [String: Any]) {
        var criptextEmails = [username: "peer"] as [String: String]
        var toArray = [String]()
        var ccArray = [String]()
        var bccArray = [String]()
        
        let toContacts = email.getContacts(type: .to)
        for contact in toContacts {
            if(contact.email.contains(Env.domain)){
                criptextEmails[String(contact.email.split(separator: "@")[0])] = "to"
            } else {
                toArray.append(contact.email)
            }
        }
        
        let ccContacts = email.getContacts(type: .cc)
        for contact in ccContacts {
            if(contact.email.contains(Env.domain)){
                criptextEmails[String(contact.email.split(separator: "@")[0])] = "cc"
            } else {
                ccArray.append(contact.email)
            }
        }
        
        let bccContacts = email.getContacts(type: .bcc)
        for contact in bccContacts {
            if(contact.email.contains(Env.domain)){
                criptextEmails[String(contact.email.split(separator: "@")[0])] = "bcc"
            } else {
                bccArray.append(contact.email)
            }
        }
        
        var guestEmails = [String : Any]()
        if(!toArray.isEmpty || !ccArray.isEmpty || !bccArray.isEmpty){
            let body = email.content + SendMailAsyncTask.buildAttachmentsHtml(attachments: files, keys: fileKey)
            guestEmails["to"] = toArray
            guestEmails["cc"] = ccArray
            guestEmails["bcc"] = bccArray
            guestEmails["body"] = "\(body)\(email.secure ? "" : Constants.footer)"
            if let fKey = fileKey {
                guestEmails["fileKey"] = fKey
            }
        }
        return (guestEmails, criptextEmails)
    }
    
    func start(completion: @escaping ((ResponseData) -> Void)){
        let queue = DispatchQueue(label: "com.email.sendmail", qos: .background, attributes: .concurrent)
        queue.async {
            self.getDuplicatedFiles(queue: queue, completion: completion)
        }
    }
    
    private func getDuplicatedFiles(queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)) {
        guard !duplicates.isEmpty else {
            getSessionAndEncrypt(queue: queue, completion: completion)
            return
        }
        guard let myAccount = SharedDB.getAccountByUsername(self.username) else {
            completion(ResponseData.Error(CriptextError(message: "Unable to handle email")))
            return
        }
        APIManager.duplicateFiles(filetokens: self.duplicates, token: myAccount.jwt, queue: queue) { (responseData) in
            guard case let .SuccessDictionary(response) = responseData,
                let duplicates = response["duplicates"] as? [String: Any],
                let fileParams = SharedDB.duplicateFiles(key: self.emailKey, duplicates: duplicates) else {
                completion(ResponseData.Error(CriptextError(message: "Unable to handle file duplicates")))
                return
            }
            self.files.append(contentsOf: fileParams)
            if self.guestEmails["body"] != nil {
                let body = self.body + SendMailAsyncTask.buildAttachmentsHtml(attachments: self.files, keys: self.fileKey)
                self.guestEmails["body"] = "\(body)\(self.isSecure ? "" : Constants.footer)"
            }
            self.getSessionAndEncrypt(queue: queue, completion: completion)
        }
    }
    
    private func getSessionAndEncrypt(queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        guard let myAccount = SharedDB.getAccountByUsername(self.username) else {
            completion(ResponseData.Error(CriptextError(message: "Unable to handle email")))
            return
        }
        
        if isSecure && !guestEmails.isEmpty {
            if let enteredPassword = password {
                let dummySessionData = self.buildDummySession(password: enteredPassword, myAccount: myAccount)
                self.guestEmails["body"] = dummySessionData.body
                self.guestEmails["session"] = dummySessionData.session
                let dummySession = DummySession()
                dummySession.body = dummySessionData.body
                dummySession.session = dummySessionData.session
                dummySession.key = emailKey
                SharedDB.store(dummySession)
            } else if let dummySession = SharedDB.getDummySession(key: emailKey) {
                self.guestEmails["body"] = dummySession.body
                self.guestEmails["session"] = dummySession.session
            } else {
                deleteUnhandledEmail()
                completion(ResponseData.Error(CriptextError(message: "Unable to handle email")))
                return
            }
        }
        
        var recipients = [String]()
        var knownAddresses = [String: [Int32]]()
        var criptextEmailsData = [[String: Any]]()
        for (recipientId, type) in criptextEmails {
            let type = type as! String
            let recipientSessions = DBAxolotl.getSessionRecords(recipientId: recipientId)
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
        
        APIManager.getKeysRequest(params, token: myAccount.jwt, queue: queue) { responseData in
            guard let myAccount = SharedDB.getAccountByUsername(self.username) else {
                return
            }
            guard case let .SuccessArray(keysArray) = responseData else {
                self.setEmailAsFailed()
                DispatchQueue.main.async {
                    completion(responseData)
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
    
    private func sendMail(myAccount: Account, criptextEmails: [Any], queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        guard let myAccount = SharedDB.getAccountByUsername(self.username) else {
            return
        }
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
        APIManager.postMailRequest(requestParams, token: myAccount.jwt, queue: queue) { responseData in
            if case .TooManyRequests = responseData {
                DispatchQueue.main.async {
                    self.setEmailAsFailed()
                    completion(ResponseData.Error(CriptextError(message: "Failed to send e-mail. Email cap reached. It will be sent later.")))
                }
                return
            }
            guard case let .SuccessDictionary(updateData) = responseData else {
                DispatchQueue.main.async {
                    self.setEmailAsFailed()
                    completion(responseData)
                }
                return
            }
            guard let key = self.updateEmailData(updateData) else {
                DispatchQueue.main.async {
                    completion(ResponseData.Error(CriptextError(code: .noValidResponse)))
                }
                return
            }
            DispatchQueue.main.async {
                SharedDB.refresh()
                completion(ResponseData.SuccessInt(key))
            }
        }
    }
    
    func setEmailAsFailed(){
        guard let email = SharedDB.getObject(emailRef) as? Email else {
            return
        }
        SharedDB.updateEmail(email, status: Email.Status.fail.rawValue)
    }
    
    func deleteUnhandledEmail(){
        guard let email = SharedDB.getObject(emailRef) as? Email else {
            return
        }
        SharedDB.setLabelsForEmail(email, labels: [SystemLabel.trash.id])
    }
    
    func updateEmailData(_ updateData : [String: Any]) -> Int? {
        guard let email = SharedDB.getObject(emailRef) as? Email else {
            return nil
        }
        let key = updateData["metadataKey"] as! Int
        let messageId = updateData["messageId"] as! String
        let threadId = updateData["threadId"] as! String
        SharedDB.updateEmail(email, key: key, messageId: messageId, threadId: threadId)
        SharedDB.deleteDummySession(key: emailKey)
        updateFiles(emailId: key)
        return key
    }
    
    func updateFiles(emailId: Int){
        for file in files {
            guard let filetoken = file["token"] as? String else {
                continue
            }
            SharedDB.update(filetoken: filetoken, emailId: emailId)
        }
    }
    
    private class func buildAttachmentsHtml(attachments: [[String: Any]], keys: String?) -> String {
        return ""
    }
    
    private class func buildAttachmentHtml(name: String, mimeType: String, size: String, encodedParams: String) -> String{
        return """
        <div style="margin-top: 6px; float: left;">
            <a style="cursor: pointer; text-decoration: none;" href="https://services.criptext.com/downloader/\(encodedParams)">
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
