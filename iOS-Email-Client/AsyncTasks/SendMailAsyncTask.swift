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
    
    internal struct Recipients {
        var tos = [String: [String]]()
        var ccs = [String: [String]]()
        var bccs = [String: [String]]()
        var peers = [String: [String]]()
        var domains = Set<String>()
    }
    
    var apiManager: APIManager.Type = APIManager.self
    
    let fileKey: String?
    var fileKeys: [String]?
    let threadId: String?
    let subject: String
    let body: String
    var files: [[String: Any]]
    let duplicates: [String]
    let password: String?
    var isSecure: Bool
    let accountId: String
    let emailKey: Int
    let replyTo: String?
    let fromAddressId: Int?
    let preview: String
    let emailRef: ThreadSafeReference<Object>
    let recipients: Recipients
    var recipientIdDevices: [String: Set<Int32>] = [:]
    var aliasOrigin: [String: String] = [:]
    
    init(email: Email, emailBody: String, password: String?){
        let fileParams = SendMailAsyncTask.getFilesRequestData(email: email)
        let files = fileParams.0
        let duplicates = fileParams.1
        let fileKey: String? = email.files.first(where: {!$0.fileKey.isEmpty})?.fileKey
        let domain = email.account.domain ?? Env.plainDomain
        let recipients = SendMailAsyncTask.getRecipientEmails(username: email.account.username, domain: domain, email: email)
        self.recipients = recipients
        self.fileKeys = !fileParams.2.isEmpty ? fileParams.2 : nil
        self.accountId = email.account.compoundKey
        self.emailKey = email.key
        self.subject = email.subject
        self.body = emailBody
        self.preview = email.preview
        self.isSecure = password != nil ? true : email.secure
        self.threadId = email.threadId.isEmpty || email.threadId == email.key.description ? nil : email.threadId
        self.files = files
        self.duplicates = duplicates
        self.emailRef = SharedDB.getReference(email)
        self.fileKey = fileKey
        self.password = password
        self.replyTo = email.replyTo
        
        if let fromContact = email.getContacts(type: .from).first,
            fromContact.email != email.account.email {
            let emailSplit = fromContact.email.split(separator: "@").map({$0.description})
            let domain = emailSplit.last! == Env.plainDomain ? nil : emailSplit.last!
            let alias = SharedDB.getAlias(username: emailSplit.first!, domain: domain, account: email.account)
            fromAddressId = alias?.rowId
        } else {
            fromAddressId = nil
        }
    }
    
    private class func getFilesRequestData(email: Email) -> ([[String: Any]], [String], [String]){
        var files = [[String: Any]]()
        var duplicates = [String]()
        var fileKeys = [String]()
        var duplicatedFileKeys = [String]()
        for file in email.files {
            if (file.shouldDuplicate) {
                guard let token = file.originalToken else {
                    continue
                }
                duplicates.append(token)
                duplicatedFileKeys.append(file.fileKey)
            } else {
                let fileparams = ["token": file.token,
                                  "name": file.name,
                                  "size": file.size,
                                  "mimeType": file.mimeType] as [String : Any]
                files.append(fileparams)
                fileKeys.append(file.fileKey)
            }
        }
        return (files, duplicates, fileKeys + duplicatedFileKeys)
    }
    
    private class func getRecipientEmails(username: String, domain: String, email: Email) -> Recipients {
        var recipients = Recipients()
        recipients.peers[domain] = [username]
        recipients.domains.insert(domain)
        
        let toContacts = email.getContacts(type: .to)
        for contact in toContacts {
            let emailSplit = contact.email.split(separator: "@")
            guard let emailUsername = emailSplit.first?.description ,
                let emailDomain = emailSplit.last?.description else {
                continue
            }
            if recipients.tos[emailDomain] == nil {
                recipients.tos[emailDomain] = [String]()
            }
            recipients.tos[emailDomain]?.append(emailUsername)
            recipients.domains.insert(emailDomain)
        }
        
        let ccContacts = email.getContacts(type: .cc)
        for contact in ccContacts {
            let emailSplit = contact.email.split(separator: "@")
            guard let emailUsername = emailSplit.first?.description ,
                let emailDomain = emailSplit.last?.description else {
                    continue
            }
            if recipients.ccs[emailDomain] == nil {
                recipients.ccs[emailDomain] = [String]()
            }
            recipients.ccs[emailDomain]?.append(emailUsername)
            recipients.domains.insert(emailDomain)
        }
        
        let bccContacts = email.getContacts(type: .bcc)
        for contact in bccContacts {
            let emailSplit = contact.email.split(separator: "@")
            guard let emailUsername = emailSplit.first?.description ,
                let emailDomain = emailSplit.last?.description else {
                    continue
            }
            if recipients.bccs[emailDomain] == nil {
                recipients.bccs[emailDomain] = [String]()
            }
            recipients.bccs[emailDomain]?.append(emailUsername)
            recipients.domains.insert(emailDomain)
        }
        
        return recipients
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
        guard let myAccount = SharedDB.getAccountById(self.accountId) else {
            completion(ResponseData.Error(CriptextError(message: String.localize("UNABLE_HANDLE_MAIL"))))
            return
        }
        apiManager.duplicateFiles(filetokens: self.duplicates, token: myAccount.jwt, queue: queue) { (responseData) in
            guard case let .SuccessDictionary(response) = responseData,
                let myAccount = SharedDB.getAccountById(self.accountId),
                let duplicates = response["duplicates"] as? [String: Any],
                let fileParams = SharedDB.duplicateFiles(account: myAccount, key: self.emailKey, duplicates: duplicates) else {
                completion(ResponseData.Error(CriptextError(message: String.localize("UNABLE_HANDLE_DUPLICATE"))))
                return
            }
            self.files.append(contentsOf: fileParams)
            self.getSessionAndEncrypt(queue: queue, completion: completion)
        }
    }
    
    private func getSessionAndEncrypt(queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        guard let myAccount = SharedDB.getAccountById(self.accountId) else {
            completion(ResponseData.Error(CriptextError(message: String.localize("UNABLE_HANDLE_MAIL"))))
            return
        }
        
        let keysPayload = getRecipientsAndKnownDevices(myAccount: myAccount)
        
        apiManager.getKeysRequest(keysPayload, token: myAccount.jwt, queue: queue) { responseData in
            guard let myAccount = SharedDB.getAccountById(self.accountId) else {
                return
            }
            guard case let .SuccessDictionary(keysArray) = responseData else {
                self.setEmailAsFailed()
                DispatchQueue.main.async {
                    completion(responseData)
                }
                return
            }
            let guestDomains = self.buildSessions(keysData: keysArray, myAccount: myAccount)
            guard let emailsData = self.createSendEmailData(myAccount: myAccount, guestDomains: guestDomains) else {
                completion(ResponseData.Error(CriptextError(message: String.localize("UNABLE_HANDLE_MAIL"))))
                return
            }
            let sendEmailData = SendEmailData(criptextEmails: emailsData.0, guestEmails: emailsData.1)
            sendEmailData.files = self.files
            sendEmailData.subject = self.subject
            sendEmailData.threadId = self.threadId
            sendEmailData.fromAddressId = self.fromAddressId
            self.sendMail(myAccount: myAccount, sendEmailData: sendEmailData, queue: queue, completion: completion)
        }
    }
    
    private func buildAliasesOrigins(addresses: [[String: Any]], myAccount: Account){
        for address in addresses {
            let domain = address["domain"] as! String
            let users = address["users"] as! [[String: Any]]
            
            for user in users {
                let username = user["username"] as! String
                let alias = user["alias"] as! String
                let originalDomain = user["originalDomain"] as! String
                let aliasRecipientId = domain == Env.plainDomain ? alias : "\(alias)@\(domain)"
                let originalRecipientId = originalDomain == Env.plainDomain ? username : "\(username)@\(originalDomain)"
                
                aliasOrigin[aliasRecipientId] = originalRecipientId
                
                if (recipientIdDevices[originalRecipientId] == nil) {
                    let recipientSessions = DBAxolotl.getSessionRecords(recipientId: originalRecipientId, account: myAccount)
                    recipientIdDevices[originalRecipientId] = Set(recipientSessions.map { $0.deviceId })
                }
                recipientIdDevices.removeValue(forKey: aliasRecipientId)
            }
        }
    }
    
    private func buildSessions(keysData: [String: Any], myAccount: Account) -> [String] {
        let keyBundles = keysData["keyBundles"] as! [[String:Any]]
        let blackListedDevices = keysData["blacklistedKnownDevices"] as! [[String:Any]]
        let guestDomains = keysData["guestDomains"] as! [String]
        let addresses = keysData["addresses"] as! [[String: Any]]
        
        buildAliasesOrigins(addresses: addresses, myAccount: myAccount)
        
        if(guestDomains.count > 0 && password == nil){
            self.isSecure = false
        }
        
        let store: CriptextSessionStore = CriptextSessionStore(account: myAccount)
        for blackDevice in blackListedDevices {
            guard let devices = blackDevice["devices"] as? [Int32],
                let username = blackDevice["name"] as? String,
                let domain = blackDevice["domain"] as? String else {
                    continue
            }
            let recipientId = "@\(domain)" == Env.domain ? username : "\(username)@\(domain)"
            for device in devices {
                recipientIdDevices[recipientId]?.remove(device)
                store.deleteSession(
                    forContact: recipientId,
                    deviceId: device
                )
            }
        }
        for keys in keyBundles {
            guard let username = keys["recipientId"] as? String,
                let deviceId = keys["deviceId"] as? Int32,
                let domain = keys["domain"] as? String else {
                    continue
            }
            let recipientId = "@\(domain)" == Env.domain ? username : "\(username)@\(domain)"
            if let devicesIds = recipientIdDevices[recipientId],
                devicesIds.contains(deviceId) {
                continue
            }
            if (recipientIdDevices[recipientId] == nil) {
                recipientIdDevices[recipientId] = Set<Int32>()
            }
            recipientIdDevices[recipientId]?.insert(deviceId)
            SignalHandler.buildSession(recipientId: recipientId, deviceId: deviceId, keys: keys, account: myAccount)
        }
        
        return guestDomains
    }
    
    private func handleDummySession(myAccount: Account) throws -> SendEmailData.GuestContent? {
        if isSecure {
            if let enteredPassword = password {
                let dummySessionData = self.buildDummySession(password: enteredPassword, myAccount: myAccount)
                let dummySession = DummySession()
                dummySession.body = dummySessionData.body
                dummySession.session = dummySessionData.session
                dummySession.key = emailKey
                SharedDB.store(dummySession)
                return dummySessionData
            } else if let dummySession = SharedDB.getDummySession(key: emailKey) {
                return SendEmailData.GuestContent(body: dummySession.body, session: dummySession.session)
            } else {
                throw CriptextError(message: "No Dummy Session")
            }
        }
        return nil
    }
    
    private func getRecipientsAndKnownDevices(myAccount: Account) -> [String: [[String: Any]]] {
        var recipientsByDomains = [[String: Any]]()
        
        for domain in self.recipients.domains {
            var domainDic = [String: Any]()
            var recipients = [String]()
            var knownAddresses = [String: [Int32]]()
            
            let tos = self.recipients.tos[domain] ?? []
            let ccs = self.recipients.ccs[domain] ?? []
            let bccs = self.recipients.bccs[domain] ?? []
            let peers = self.recipients.peers[domain] ?? []
            
            let allRecipients = tos + ccs + bccs + peers
            
            for username in allRecipients {
                let recipientId = domain == Env.plainDomain ? username : "\(username)@\(domain)"
                let recipientSessions = DBAxolotl.getSessionRecords(recipientId: recipientId, account: myAccount)
                let deviceIds = recipientSessions.map { $0.deviceId }
                recipients.append(username)
                recipientIdDevices[recipientId] = Set(deviceIds)
                knownAddresses[username] = deviceIds
            }
            if allRecipients.count > 0 {
                domainDic["name"] = domain
                domainDic["recipients"] = recipients
                domainDic["knownAddresses"] = knownAddresses
                recipientsByDomains.append(domainDic)
            }
        }
        return ["domains": recipientsByDomains]
    }
    
    private func createSendEmailData(myAccount: Account, guestDomains: [String]) -> ([[String: Any]], [String: Any])? {
        var criptextEmailData = [[String: Any]]()
        var guestEmailData = [String: Any]()
        
        let peerData = createEmailData(myAccount: myAccount, recipients: self.recipients.peers, contactType: "peer", guestDomains: guestDomains)
        let toData = createEmailData(myAccount: myAccount, recipients: self.recipients.tos, contactType: "to", guestDomains: guestDomains)
        let ccData = createEmailData(myAccount: myAccount, recipients: self.recipients.ccs, contactType: "cc", guestDomains: guestDomains)
        let bccData = createEmailData(myAccount: myAccount, recipients: self.recipients.bccs, contactType: "bcc", guestDomains: guestDomains)
        criptextEmailData.append(contentsOf: peerData.0)
        criptextEmailData.append(contentsOf: toData.0)
        criptextEmailData.append(contentsOf: ccData.0)
        criptextEmailData.append(contentsOf: bccData.0)
        
        if !toData.1.isEmpty {
            guestEmailData["to"] = toData.1
        }
        if !ccData.1.isEmpty {
            guestEmailData["cc"] = ccData.1
        }
        if !bccData.1.isEmpty {
            guestEmailData["bcc"] = bccData.1
        }
        if !guestEmailData.isEmpty {
            var showFooter = true
            if(myAccount.domain != nil){
                showFooter = false
            } else {
                showFooter = myAccount.showCriptextFooter
            }
            guestEmailData["body"] = self.isSecure || !showFooter ? self.body : "\(self.body)<br/><br/>\(Constants.footer)"
            guestEmailData["encrypted"] = isSecure
            
            var dummySession: SendEmailData.GuestContent?
            do {
                dummySession = try handleDummySession(myAccount: myAccount)
            } catch {
                return nil
            }
            
            if isSecure,
                let dummy = dummySession {
                guestEmailData["body"] = dummy.body
                guestEmailData["session"] = dummy.session
            } else if let fKey = fileKey {
                guestEmailData["fileKey"] = fKey
                guestEmailData["fileKeys"] = fileKeys
            }
        }
        
        return (criptextEmailData, guestEmailData)
    }
    
    private func createEmailData(myAccount: Account, recipients: [String: [String]], contactType: String, guestDomains: [String]) -> ([[String: Any]], [String]) {
        var criptextEmailData = [[String: Any]]()
        var emptyEmails = [String]()
        
        for (domain, usernames) in recipients {
            for username in usernames {
                guard !guestDomains.contains(domain) else {
                    emptyEmails.append("\(username)@\(domain)")
                    continue
                }
                var domainToSend = domain
                var isAlias = false
                var recipientId = "@\(domain)" == Env.domain ? username : "\(username)@\(domain)"
                if let originalRecipientId = aliasOrigin[recipientId] {
                    recipientId = originalRecipientId
                    domainToSend = recipientId.contains("@") ? recipientId.split(separator: "@")[1].description : Env.plainDomain
                    isAlias = true
                }
                
                let deviceIds = recipientIdDevices[recipientId]!
                var emailsData = [[String: Any]]()
                for deviceId in deviceIds {
                    guard !(contactType == "peer" && recipientId == myAccount.username && deviceId == myAccount.deviceId) else {
                        continue
                    }
                    let criptextEmail = self.buildCriptextEmail(recipientId: recipientId, deviceId: deviceId, domain: domain, myAccount: myAccount)
                    emailsData.append(criptextEmail)
                }
                if recipientId == myAccount.username && emailsData.isEmpty {
                    continue
                }
                guard isAlias else {
                    criptextEmailData.append([
                        "type": contactType,
                        "username": username,
                        "domain": domainToSend,
                        "emails": emailsData
                        ] as [String : Any])
                    continue
                }
                let aliasUsername = username
                let originalUsername = recipientId.contains("@") ? recipientId.split(separator: "@").first!.description : recipientId
                criptextEmailData.append([
                    "type": contactType,
                    "username": originalUsername,
                    "domain": domainToSend,
                    "alias": aliasUsername,
                    "emails": emailsData
                    ] as [String : Any])
            }
        }
        
        return (criptextEmailData, emptyEmails)
    }
    
    private func buildCriptextEmail(recipientId: String, deviceId: Int32, domain: String, myAccount: Account) -> [String: Any] {
        let message = SignalHandler.encryptMessage(body: self.body, deviceId: deviceId, recipientId: recipientId, account: myAccount)
        let preview = SignalHandler.encryptMessage(body: self.preview, deviceId: deviceId, recipientId: recipientId, account: myAccount)
        var criptextEmail = ["recipientId": recipientId.split(separator: "@").first ?? recipientId,
                             "deviceId": deviceId,
                             "body": message.0,
                             "messageType": message.1.rawValue,
                             "preview": preview.0,
                             "previewMessageType": preview.1.rawValue] as [String: Any]
        if !self.files.isEmpty,
            let fileKey = self.fileKey {
            criptextEmail["fileKey"] = SignalHandler.encryptMessage(body: fileKey, deviceId: deviceId, recipientId: recipientId, account: myAccount).0
            if let fileKeys = self.fileKeys {
                var criptextFileKeys:[String]? = [String]()
                for key in fileKeys{
                    criptextFileKeys?.append(SignalHandler.encryptMessage(body: key, deviceId: deviceId, recipientId: recipientId, account: myAccount).0)
                }
                criptextEmail["fileKeys"] = criptextFileKeys
            }
        }
        return criptextEmail
    }
    
    private func buildDummySession(password: String, myAccount: Account) -> SendEmailData.GuestContent {
        let dummy = Dummy(recipientId: password)
        let keyBundle = dummy.getKeyBundle()
        let body = encryptDummyBody(keys: keyBundle, myAccount: myAccount)
        var session = dummy.getSessionBundle()
        if let fileKey = self.fileKey {
            session["fileKey"] = fileKey
        }
        if let fileKeys = self.fileKeys {
            session["fileKeys"] = fileKeys
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
    
    private func sendMail(myAccount: Account, sendEmailData: SendEmailData, queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        guard let myAccount = SharedDB.getAccountById(self.accountId) else {
            return
        }
        
        apiManager.postMailRequest(sendEmailData.buildRequestData(), token: myAccount.jwt, queue: queue) { responseData in
            if case .TooManyRequests = responseData {
                DispatchQueue.main.async {
                    self.setEmailAsFailed()
                    completion(ResponseData.Error(CriptextError(message: String.localize("EMAIL_CAP_MAX"))))
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
            
            guard let myAccount = SharedDB.getAccountById(self.accountId) else {
                return
            }
            FileUtils.deleteDirectoryFromEmail(account: myAccount, metadataKey: "\(self.emailKey)")
            FileUtils.saveEmailToFile(email: myAccount.email, metadataKey: "\(updateData["metadataKey"] as! Int)", body: self.body, headers: "")
            
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
        SharedDB.updateEmail(email, key: key, messageId: messageId, threadId: threadId, isSecure: self.isSecure)
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
    
}
