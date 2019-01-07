//
//  NewEmailHandler.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftSoup

class NewEmailHandler {
    
    var database: SharedDB.Type = SharedDB.self
    var api: SharedAPI.Type = SharedAPI.self
    let username: String
    let PREVIEW_SIZE = 300
    let queue: DispatchQueue?
    
    init(username: String, queue: DispatchQueue? = nil){
        self.username = username
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
        guard let myAccount = database.getAccountByUsername(self.username) else {
            completion(Result(success: false))
            return
        }
        let event = NewEmail.init(params: params)
        
        if let email = self.database.getMailByKey(key: event.metadataKey) {
            if(isMeARecipient(email: email, account: myAccount)){
                self.database.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.inbox.id], removedLabelIds: [])
                completion(Result(email: email))
                return
            }
            completion(Result(success: true))
            return
        }
        
        api.getEmailBody(metadataKey: event.metadataKey, account: myAccount, queue: self.queue) { (responseData) in
            var error: CriptextError?
            var unsent = false
            if case let .Error(err) = responseData {
                error = err
            }
            if case .Missing = responseData {
                unsent = true
            }
            
            guard (unsent || error == nil),
                let myAccount = self.database.getAccountByUsername(self.username),
                case let .SuccessString(body) = responseData,
                let username = ContactUtils.getUsernameFromEmailFormat(event.from) else {
                    completion(Result(success: false))
                    return
            }
            guard let content = unsent ? "" : self.handleBodyByMessageType(event.messageType, body: body, account: myAccount, recipientId: username, senderDeviceId: event.senderDeviceId, isExternal: event.isExternal) else {
                    completion(Result(success: true))
                    return
            }
            
            let contentPreview = self.getContentPreview(content: content)
            let email = Email()
            email.threadId = event.threadId
            email.subject = event.subject
            email.key = event.metadataKey
            email.messageId = event.messageId
            email.date = event.date
            email.unread = true
            email.content = contentPreview.1
            email.preview = contentPreview.0
            
            if(unsent){
                email.unsentDate = email.date
                email.status = .unsent
            }
            
            if let attachments = event.files {
                for attachment in attachments {
                    let file = self.handleAttachment(attachment, email: email)
                    email.files.append(file)
                }
            }
            
            if self.isFromMe(email: email, account: myAccount, event: event),
                let sentLabel = SharedDB.getLabel(SystemLabel.sent.id) {
                email.delivered = Email.Status.sent.rawValue
                email.unread = false
                email.labels.append(sentLabel)
                if self.isMeARecipient(email: email, account: myAccount, event: event),
                    let inboxLabel = SharedDB.getLabel(SystemLabel.inbox.id) {
                    email.unread = true
                    email.labels.append(inboxLabel)
                }
            } else if let inboxLabel = SharedDB.getLabel(SystemLabel.inbox.id) {
                email.labels.append(inboxLabel)
            }
            
            if(!event.labels.isEmpty){
                let labels = event.labels.reduce([Label](), { (labelsArray, labelText) -> [Label] in
                    guard let label = SharedDB.getLabel(text: labelText) else {
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
            
            if !unsent,
                let keyString = event.fileKey,
                let fileKeyString = self.handleBodyByMessageType(event.messageType, body: keyString, account: myAccount, recipientId: username, senderDeviceId: event.senderDeviceId, isExternal: event.isExternal) {
                let fKey = FileKey()
                fKey.emailId = email.key
                fKey.key = fileKeyString
                self.database.store([fKey])
            }
            
            ContactUtils.parseEmailContacts([event.from], email: email, type: .from)
            ContactUtils.parseEmailContacts(event.to, email: email, type: .to)
            ContactUtils.parseEmailContacts(event.cc, email: email, type: .cc)
            ContactUtils.parseEmailContacts(event.bcc, email: email, type: .bcc)
            
            if let myContact = SharedDB.getContact("\(myAccount.username)\(Env.domain)"),
                myContact.displayName != myAccount.name {
                SharedDB.update(contact: myContact, name: myAccount.name)
            }
            
            completion(Result(email: email))
        }
    }
    
    func handleBodyByMessageType(_ messageType: MessageType, body: String, account: Account, recipientId: String, senderDeviceId: Int32?, isExternal: Bool) -> String? {
        let recipient = isExternal ? "bob" : recipientId
        let senderDevice = isExternal ? 1 : senderDeviceId
        guard messageType != .none,
            let deviceId = senderDevice else {
                return body
        }
        var trueBody : String?
        tryBlock {
            trueBody = SignalHandler.decryptMessage(body, messageType: messageType, account: account, recipientId: recipient, deviceId: deviceId)
        }
        return trueBody
    }
    
    func handleAttachment(_ attachment: [String: Any], email: Email) -> File {
        let file = File()
        file.token = attachment["token"] as! String
        file.size = attachment["size"] as! Int
        file.name = attachment["name"] as! String
        if let fileKey = attachment["fileKey"] {
            file.fileKey = fileKey as! String
        }
        file.mimeType = File.mimeTypeForPath(path: file.name)
        file.date = email.date
        file.readOnly = attachment["read_only"] as? Int ?? 0
        file.emailId = email.key
        database.store(file)
        return file
    }
    
    func isMeARecipient(email: Email, account: Account) -> Bool {
        let accountEmail = "\(account.username)\(Env.domain)"
        let bccContacts = Array(email.getContacts(type: .bcc))
        let ccContacts = Array(email.getContacts(type: .cc))
        let toContacts = Array(email.getContacts(type: .to))
        return bccContacts.contains(where: {$0.email == accountEmail})
            || ccContacts.contains(where: {$0.email == accountEmail})
            || toContacts.contains(where: {$0.email == accountEmail})
    }
    
    func isFromMe(email: Email, account: Account) -> Bool {
        let accountEmail = "\(account.username)\(Env.domain)"
        return accountEmail == email.fromContact.email
    }
    
    func isMeARecipient(email: Email, account: Account, event: NewEmail) -> Bool {
        let accountEmail = "\(account.username)\(Env.domain)"
        let isInBcc = event.bcc.contains(where: {ContactUtils.getStringEmailName(contact: $0).0 == accountEmail})
        let isInCc = event.cc.contains(where: {ContactUtils.getStringEmailName(contact: $0).0 == accountEmail})
        let isInTo = event.to.contains(where: {ContactUtils.getStringEmailName(contact: $0).0 == accountEmail})
        return isInBcc || isInCc || isInTo
    }
    
    func isFromMe(email: Email, account: Account, event: NewEmail) -> Bool {
        let accountEmail = "\(account.username)\(Env.domain)"
        return accountEmail == ContactUtils.getStringEmailName(contact: event.from).0
    }
    
    func getContentPreview(content: String) -> (String, String) {
        do {
            let allowList = try SwiftSoup.Whitelist.relaxed().addTags("style", "title", "header").addAttributes(":all", "class", "style", "src")
            let doc: Document = try SwiftSoup.parse(content)
            let preview = try String(doc.text().prefix(self.PREVIEW_SIZE))
            let cleanContent = try SwiftSoup.clean(content, allowList)!
            return (preview, cleanContent)
        } catch {
            let preview = String(content.prefix(self.PREVIEW_SIZE))
            return (preview, content)
        }
    }
}
