//
//  NewEmailHandler.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftSoup

class NewEmailHandler {
    
    var database: SharedDB.Type = SharedDB.self
    var api: SharedAPI.Type = SharedAPI.self
    
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
        guard let myAccount = database.getFirstAccount() else {
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
        
        let email = Email()
        email.threadId = event.threadId
        email.subject = event.subject
        email.key = event.metadataKey
        email.messageId = event.messageId
        email.date = event.date
        email.unread = true
        
        if let attachments = event.files {
            for attachment in attachments {
                let file = self.handleAttachment(attachment, email: email)
                email.files.append(file)
            }
        }
        
        api.getEmailBody(metadataKey: email.key, token: myAccount.jwt) { (responseData) in
            
            var error: CriptextError?
            var unsent = false
            if case let .Error(err) = responseData {
                error = err
            }
            if case .Missing = responseData {
                unsent = true
            }
            
            guard (unsent || error == nil),
                let myAccount = self.database.getFirstAccount(),
                case let .SuccessString(body) = responseData,
                let username = ContactUtils.getUsernameFromEmailFormat(event.from),
                let content = unsent ? "" : self.handleBodyByMessageType(event.messageType, body: body, account: myAccount, recipientId: username, senderDeviceId: event.senderDeviceId) else {
                    completion(Result(success: false))
                    return
            }
            
            let contentPreview = self.getContentPreview(content: content)
            email.content = contentPreview.1
            email.preview = contentPreview.0
            
            if(unsent){
                email.unsentDate = email.date
                email.status = .unsent
            }
            guard self.database.store(email) else {
                completion(Result(success: true))
                return
            }
            
            if !unsent,
                let keyString = event.fileKey,
                let fileKeyString = self.handleBodyByMessageType(event.messageType, body: keyString, account: myAccount, recipientId: username, senderDeviceId: event.senderDeviceId) {
                let fKey = FileKey()
                fKey.emailId = email.key
                fKey.key = fileKeyString
                self.database.store([fKey])
            }
            
            ContactUtils.parseEmailContacts([event.from], email: email, type: .from)
            ContactUtils.parseEmailContacts(event.to, email: email, type: .to)
            ContactUtils.parseEmailContacts(event.cc, email: email, type: .cc)
            ContactUtils.parseEmailContacts(event.bcc, email: email, type: .bcc)
            
            if(self.isFromMe(email: email, account: myAccount)){
                self.database.updateEmail(email, status: .sent)
                self.database.updateEmail(email, unread: false)
                self.database.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.sent.id], removedLabelIds: [])
            }
            if(self.isMeARecipient(email: email, account: myAccount)){
                self.database.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.inbox.id], removedLabelIds: [])
            }
            if(!event.labels.isEmpty){
                let labels = event.labels.map({ (labelName) -> Int in
                    return SystemLabel.fromText(text: labelName)
                })
                self.database.addRemoveLabelsFromEmail(email, addedLabelIds: labels, removedLabelIds: [])
            }
            
            completion(Result(email: email))
        }
    }
    
    func handleBodyByMessageType(_ messageType: MessageType, body: String, account: Account, recipientId: String, senderDeviceId: Int32?) -> String? {
        guard messageType != .none,
            let deviceId = senderDeviceId else {
                return body
        }
        return SignalHandler.decryptMessage(body, messageType: messageType, account: account, recipientId: recipientId, deviceId: deviceId)
    }
    
    func handleAttachment(_ attachment: [String: Any], email: Email) -> File {
        let file = File()
        file.token = attachment["token"] as! String
        file.size = attachment["size"] as! Int
        file.name = attachment["name"] as! String
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
    
    func getContentPreview(content: String) -> (String, String) {
        do {
            let allowList = try SwiftSoup.Whitelist.relaxed().addTags("style", "title", "header").addAttributes(":all", "class", "style", "src")
            let doc: Document = try SwiftSoup.parse(content)
            let preview = try String(doc.text().prefix(100))
            let cleanContent = try SwiftSoup.clean(content, allowList)!
            return (preview, cleanContent)
        } catch {
            let preview = String(content.prefix(100))
            return (preview, content)
        }
    }
}
