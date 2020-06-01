//
//  NewEmailHandler.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftSoup
import FirebaseAnalytics
import FirebaseCrashlytics

class NewEmailHandler {
    
    var database: SharedDB.Type = SharedDB.self
    var api: SharedAPI.Type = SharedAPI.self
    var signal: SignalHandler.Type = SignalHandler.self
    let accountId: String
    let PREVIEW_SIZE = 300
    let queue: DispatchQueue?
    
    init(accountId: String, queue: DispatchQueue? = nil, domain: String? = nil){
        self.accountId = accountId
        self.queue = queue
    }
    
    struct Result {
        let email: Email?
        let success: Bool
        
        init(success: Bool) {
            self.success = success
            self.email = nil
        }
        
        init(email: Email) {
            self.email = email
            self.success = true
        }
    }
    
    func command(params: [String: Any], completion: @escaping (_ result: Result) -> Void){
        guard let myAccount = database.getAccountById(accountId) else {
            completion(Result(success: false))
            return
        }
        
        guard let event = try? NewEmail.init(params: params),
            let recipientId = event.recipientId else {
            completion(Result(success: false))
            return
        }
        
        if let email = self.database.getMail(key: event.metadataKey, account: myAccount) {
            if(isMeARecipient(email: email, account: myAccount)){
                self.database.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.inbox.id], removedLabelIds: [])
                completion(Result(email: email))
                return
            }
            let defaults = CriptextDefaults()
            defaults.deleteEmailStrike(id: email.compoundKey)
            completion(Result(success: true))
            return
        }
        
        api.getEmailBody(metadataKey: event.metadataKey, token: myAccount.jwt, queue: self.queue) { (responseData) in
            var unsent = false
            var content = ""
            var contentHeader: String? = nil
            guard let myAccount = self.database.getAccountById(self.accountId) else {
                completion(Result(success: false))
                return
            }
            if case .Missing = responseData {
                unsent = true
            } else if case let .SuccessDictionary(data) = responseData {
                guard let bodyString = data["body"] as? String else {
                        completion(Result(success: false))
                        return
                }
                let decryptedContentResult = self.handleContentByMessageType(
                    event.messageType, content: bodyString, account: myAccount,
                    recipientId: recipientId, senderDeviceId: event.senderDeviceId,
                    isExternal: event.isExternal)
                
                switch(decryptedContentResult) {
                    case .Content(let decryptedContent):
                        content = decryptedContent
                    case .Duplicated, .NoSession:
                        let emailId = "\(myAccount.compoundKey):\(event.metadataKey)"
                        let defaults = CriptextDefaults()
                        if defaults.getEmailStrike(id: emailId) > 2 {
                            content = String.localize("CONTENT_UNENCRYPTED")
                            defaults.deleteEmailStrike(id: emailId)
                        } else {
                            defaults.addEmailStrike(id: emailId)
                            completion(Result(success: false))
                            return
                        }
                    default:
                        content = String.localize("CONTENT_UNENCRYPTED")
                }
                
                let headers = data["headers"] as? String
                let contentHeaderResult = self.handleContentByMessageType(event.messageType, content: headers, account: myAccount, recipientId: recipientId, senderDeviceId: event.senderDeviceId, isExternal: event.isExternal)
                if case let .Content(headersResult) = contentHeaderResult {
                    contentHeader = headersResult
                }
            } else {
                completion(Result(success: false))
                return
            }
            
            guard !FileUtils.existBodyFile(email: myAccount.email, metadataKey: "\(event.metadataKey)") else {
                if let email = self.database.getMail(key: event.metadataKey, account: myAccount) {
                    completion(Result(email: email))
                    return
                }
                completion(Result(success: true))
                return
            }
            
            var replyThreadId = event.threadId
            if let inReplyTo = event.inReplyTo,
                let replyEmail = SharedDB.getEmail(messageId: inReplyTo, account: myAccount) {
                replyThreadId = replyEmail.threadId
            }
            
            let contentPreview = self.getContentPreview(content: content)
            let email = Email()
            email.account = myAccount
            email.threadId = replyThreadId
            email.subject = event.subject
            email.key = event.metadataKey
            email.messageId = event.messageId
            email.boundary = event.boundary ?? ""
            email.date = event.date
            email.unread = true
            email.secure = event.guestEncryption == 1 || event.guestEncryption == 3 ? true : false
            email.preview = contentPreview.0
            email.replyTo = event.replyTo ?? ""
            email.buildCompoundKey()
            
            if(unsent){
                email.unsentDate = email.date
                email.delivered = Email.Status.unsent.rawValue
            } else {
                FileUtils.saveEmailToFile(email: myAccount.email, metadataKey: "\(event.metadataKey)", body: contentPreview.1, headers: contentHeader)
            }
            
            self.handleAttachments(recipientId: recipientId, event: event, email: email, myAccount: myAccount, body: contentPreview.1)
            
            email.fromAddress = event.from
            var fromMe = false
            if self.isFromMe(email: email, account: myAccount, event: event),
                let sentLabel = SharedDB.getLabel(SystemLabel.sent.id) {
                fromMe = true
                if !unsent {
                    email.delivered = Email.Status.sent.rawValue
                }
                email.unread = false
                email.labels.append(sentLabel)
                if self.isMeARecipient(email: email, account: myAccount, event: event),
                    let inboxLabel = SharedDB.getLabel(SystemLabel.inbox.id) {
                    email.unread = true
                    email.labels.append(inboxLabel)
                }
            } else if let inboxLabel = SharedDB.getLabel(SystemLabel.inbox.id) {
                email.labels.append(inboxLabel)
                let fromContact = self.database.getContact(ContactUtils.parseContact(event.from, account: myAccount).email)
                if(fromContact != nil){
                    if(fromContact?.spamScore ?? 0 >= 2){
                        let spamLabel = SharedDB.getLabel(SystemLabel.spam.id)
                        email.labels.append(spamLabel!)
                    }
                }
            }
            
            if(!event.labels.isEmpty){
                let labels = event.labels.reduce([Label](), { (labelsArray, labelText) -> [Label] in
                    guard let label = SharedDB.getLabel(text: labelText),
                        (!fromMe || label.id != SystemLabel.spam.id) else {
                        return labelsArray
                    }
                    return labelsArray.appending(label)
                })
                email.labels.append(objectsIn: labels)
            }
            
            guard self.database.store(email) else {
                completion(Result(success: true))
                return
            }
            
            ContactUtils.parseEmailContacts([event.from], email: email, type: .from, account: myAccount)
            ContactUtils.parseEmailContacts(event.to, email: email, type: .to, account: myAccount)
            ContactUtils.parseEmailContacts(event.cc, email: email, type: .cc, account: myAccount)
            ContactUtils.parseEmailContacts(event.bcc, email: email, type: .bcc, account: myAccount)
            
            if let myContact = SharedDB.getContact(myAccount.email),
                myContact.displayName != myAccount.name {
                SharedDB.update(contact: myContact, name: myAccount.name)
            }
            
            completion(Result(email: email))
        }
    }
    
    enum DecryptResult {
        case Content(String)
        case Duplicated
        case NoSession
        case Uknown
    }
    
    func handleContentByMessageType(_ messageType: MessageType, content: String?, account: Account, recipientId: String, senderDeviceId: Int32?, isExternal: Bool) -> DecryptResult {
        guard let myContent = content else {
            return .Uknown
        }
        let recipient = isExternal ? "bob" : recipientId
        guard messageType != .none,
            let deviceId = senderDeviceId else {
                return .Content(myContent)
        }
        var trueBody = myContent
        let err = tryBlock {
            trueBody = self.signal.decryptMessage(myContent, messageType: messageType, account: account, recipientId: recipient, deviceId: deviceId)
        }
        if let error = err {
            let codeName = isExternal ? "CONTENT_UNENCRYPTED_BOB" : "CONTENT_UNENCRYPTED"
            let payload = [
                "name": error.name.rawValue,
                "reason": error.reason ?? "Unknown Signal Error",
                "isExternal": isExternal.description,
                "codeName": codeName
                ] as [String : Any]
            Crashlytics.crashlytics().record(error: NSError.init(domain: codeName, code: -1000, userInfo: payload))
            if (error.name.rawValue == "AxolotlDuplicateMessage") {
                return .Duplicated
            } else if (error.name.rawValue == "AxolotlNoSessionException") {
                return .NoSession
            } else {
                return .Uknown
            }
        }
        return .Content(trueBody)
    }
    
    func handleAttachments(recipientId: String, event: NewEmail, email: Email, myAccount: Account, body: String) {
        if let attachments = event.files,
            attachments.count > 0 {
            if let fileKeys = event.fileKeys {
                for (index, attachment) in attachments.enumerated() {
                    var fileKey = fileKeys[index]
                    let result = handleContentByMessageType(event.messageType, content: fileKey, account: myAccount, recipientId: recipientId, senderDeviceId: event.senderDeviceId, isExternal: event.isExternal)
                    if case let .Content(keys) = result {
                        fileKey = keys
                    }
                    let file = self.handleAttachment(attachment, email: email, fileKey: fileKey, body: body)
                    email.files.append(file)
                }
            } else  {
                var fileKey = event.fileKey ?? ""
                let result = handleContentByMessageType(event.messageType, content: fileKey, account: myAccount, recipientId: recipientId, senderDeviceId: event.senderDeviceId, isExternal: event.isExternal)
                if case let .Content(keys) = result {
                    fileKey = keys
                }
                for attachment in attachments {
                    let file = self.handleAttachment(attachment, email: email, fileKey: fileKey, body: body)
                    email.files.append(file)
                }
            }
        }
    }
    
    func handleAttachment(_ attachment: [String: Any], email: Email, fileKey: String, body: String) -> File {
        let cid = attachment["cid"] as? String
        let file = File()
        file.token = attachment["token"] as! String
        file.size = attachment["size"] as! Int
        file.name = attachment["name"] as! String
        let key = attachment["key"] as? String
        let iv = attachment["iv"] as? String
        let fileKeyIv = key != nil && iv != nil ? "\(key!):\(iv!)" : fileKey
        file.fileKey = fileKeyIv
        file.mimeType = attachment["mimeType"] as? String ?? File.mimeTypeForPath(path: file.name)
        file.date = email.date
        file.emailId = email.key
        if let fileCid = cid,
            body.contains("cid:\(fileCid)") && (UIUtils.getExternalImage(file.mimeType) == "fileimage") {
            file.cid = cid != nil && body.contains("cid:\(fileCid)") ? cid : nil
        }
        database.store(file)
        return file
    }
    
    func isMeARecipient(email: Email, account: Account) -> Bool {
        let accountEmail = account.email
        let bccContacts = Array(email.getContacts(type: .bcc))
        let ccContacts = Array(email.getContacts(type: .cc))
        let toContacts = Array(email.getContacts(type: .to))
        return bccContacts.contains(where: {$0.email == accountEmail})
            || ccContacts.contains(where: {$0.email == accountEmail})
            || toContacts.contains(where: {$0.email == accountEmail})
    }
    
    func isMeARecipient(email: Email, account: Account, event: NewEmail) -> Bool {
        let accountEmail = account.email
        let isInBcc = event.bcc.contains(where: {ContactUtils.getStringEmailName(contact: $0).0 == accountEmail})
        let isInCc = event.cc.contains(where: {ContactUtils.getStringEmailName(contact: $0).0 == accountEmail})
        let isInTo = event.to.contains(where: {ContactUtils.getStringEmailName(contact: $0).0 == accountEmail})
        return isInBcc || isInCc || isInTo
    }
    
    func isFromMe(email: Email, account: Account, event: NewEmail) -> Bool {
        let fromEmail = ContactUtils.getStringEmailName(contact: event.from).0
        if (account.email == fromEmail) {
            return true
        }
        let emailSplit = fromEmail.split(separator: "@").map({$0.description})
        let username = emailSplit.first!
        let domain = emailSplit.last! == Env.plainDomain ? nil : emailSplit.last!
        if DBManager.getAlias(username: username, domain: domain, account: account) != nil {
            return true
        }
        return false
    }
    
    func getContentPreview(content: String) -> (String, String) {
        do {
            let allowList = try SwiftSoup.Whitelist.relaxed().addTags("style", "title", "header").addAttributes(":all", "class", "style", "src", "bgcolor").addProtocols("img", "src", "cid", "data")
            let doc: Document = try SwiftSoup.parse(content)
            let preview = try String(doc.text().prefix(self.PREVIEW_SIZE))
            let cleanContent = try SwiftSoup.clean(content, allowList)! //error triggered
            return (preview, cleanContent)
        } catch {
            let preview = String(content.prefix(self.PREVIEW_SIZE))
            return (preview, content)
        }
    }
}
