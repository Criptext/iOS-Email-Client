//
//  EventHandler.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol EventHandlerDelegate {
    func didReceiveNewEmails(emails: [Email])
    func didReceiveOpens(opens: [FeedItem])
}

class EventHandler {
    let myAccount : Account
    var eventDelegate : EventHandlerDelegate?
    var apiManager : APIManager.Type = APIManager.self
    var signalHandler: SignalHandler.Type = SignalHandler.self
    
    init(account: Account){
        myAccount = account
    }

    func handleEvents(events: Array<Dictionary<String, Any>>){
        var emails = [Email]()
        var opens = [FeedItem]()
        var successfulEvents = [Int32]()
        let asyncGroupCalls = DispatchGroup()
        events.forEach({ (event) in
            asyncGroupCalls.enter()
            self.handleEvent(event){ (successfulEventId, data) in
                guard let eventId = successfulEventId else {
                    asyncGroupCalls.leave()
                    return
                }
                successfulEvents.append(eventId)
                switch(data){
                case is Email:
                    emails.append(data as! Email)
                case is FeedItem:
                    opens.append(data as! FeedItem)
                default:
                    break
                }
                asyncGroupCalls.leave()
            }
        })
        asyncGroupCalls.notify(queue: .main) {
            if(!successfulEvents.isEmpty){
                self.apiManager.acknowledgeEvents(eventIds: successfulEvents, token: self.myAccount.jwt)
            }
            self.notify(emails: emails)
            self.notify(opens: opens)
        }
    }
    
    func notify(emails: [Email]){
        guard !emails.isEmpty else {
            return
        }
        self.eventDelegate?.didReceiveNewEmails(emails: emails)
    }
    
    func notify(opens: [FeedItem]){
        guard !opens.isEmpty else {
            return
        }
        self.eventDelegate?.didReceiveOpens(opens: opens)
    }
    
    func handleEvent(_ event: Dictionary<String, Any>, finishCallback: @escaping (_ successfulEventId : Int32?, _ data: Any?) -> Void){
        let cmd = event["cmd"] as! Int32
        let rowId = event["rowid"] as? Int32
        guard let params = event["params"] as? [String : Any] ?? Utils.convertToDictionary(text: (event["params"] as! String)) else {
            finishCallback(nil, nil)
            return
        }
        switch(cmd){
        case Event.newEmail.rawValue:
            self.handleNewEmailCommand(params: params){ (successfulEvent, email)  in
                guard successfulEvent,
                    let eventId = rowId else {
                    finishCallback(nil, nil)
                    return
                }
                finishCallback(eventId, email)
            }
            break
        case Event.openEmail.rawValue:
            self.handleOpenEmailCommand(params: params){ (successfulEvent, open) in
                guard successfulEvent,
                    let eventId = rowId else {
                        finishCallback(nil, nil)
                        return
                }
                finishCallback(eventId, open)
            }
            break
        case Event.peerEmailStatus.rawValue:
            self.handlePeerEmailStatusCommand(params: params){ (successfulEvent, open) in
                guard successfulEvent,
                    let eventId = rowId else {
                        finishCallback(nil, nil)
                        return
                }
                finishCallback(eventId, open)
            }
            break
        default:
            finishCallback(nil, nil)
            break
        }
    }
    
    func handleNewEmailCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ email: Email?) -> Void){
        let event = EventData.NewEmail.init(params: params)
        
        if let email = DBManager.getMailByKey(key: event.metadataKey) {
            if(isMeARecipient(email: email)){
                DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.inbox.id], removedLabelIds: [])
                finishCallback(true, email)
                return
            }
            finishCallback(true, nil)
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
                let file = handleAttachment(attachment, email: email)
                email.files.append(file)
            }
        }
        
        apiManager.getEmailBody(messageId: email.messageId, token: myAccount.jwt) { (error, data) in
            let unsent = (error as? CriptextError)?.code == .bodyUnsent
            
            guard (unsent || error == nil),
                let username = Utils.getUsernameFromEmailFormat(event.from),
                let content = unsent ? "" : self.handleBodyByMessageType(event.messageType, body: data as! String, recipientId: username, senderDeviceId: event.senderDeviceId) else {
                finishCallback(false, nil)
                return
            }
            email.content = content
            email.preview = String(email.content.removeHtmlTags().prefix(100))
            if(unsent){
                email.unsentDate = email.date
                email.status = .unsent
            }
            DBManager.store(email)
            
            if !unsent,
                let keyString = event.fileKey,
                let fileKeyString = self.handleBodyByMessageType(event.messageType, body: keyString, recipientId: username, senderDeviceId: event.senderDeviceId) {
                let fKey = FileKey()
                fKey.emailId = email.key
                fKey.key = fileKeyString
                DBManager.store([fKey])
            }
            
            ContactUtils.parseEmailContacts(event.from, email: email, type: .from)
            ContactUtils.parseEmailContacts(event.to, email: email, type: .to)
            ContactUtils.parseEmailContacts(event.cc, email: email, type: .cc)
            ContactUtils.parseEmailContacts(event.bcc, email: email, type: .bcc)
            
            if(self.isFromMe(email: email)){
                DBManager.updateEmail(email, status: .sent)
                DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.sent.id], removedLabelIds: [])
            }
            if(self.isMeARecipient(email: email)){
                DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.inbox.id], removedLabelIds: [])
            }
            finishCallback(true, email)
        }
    }
    
    func handleBodyByMessageType(_ messageType: MessageType, body: String, recipientId: String, senderDeviceId: Int32?) -> String? {
        guard messageType != .none,
            let deviceId = senderDeviceId else {
            return body
        }
        var trueBody : String?
        tryBlock {
            trueBody = self.signalHandler.decryptMessage(body, messageType: messageType, account: self.myAccount, recipientId: recipientId, deviceId: deviceId)
        }
        return trueBody
    }
    
    func handleOpenEmailCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.EmailStatus.init(params: params)
        
        if event.type == Email.Status.unsent.rawValue,
            let email = DBManager.getMail(key: event.emailId) {
            DBManager.unsendEmail(email, date: event.date)
            finishCallback(true, email)
            return
        }
        
        guard event.from != myAccount.username else {
            finishCallback(true, nil)
            return
        }
        
        let actionType: FeedItem.Action = event.fileId == nil ? .open : .download
        guard !DBManager.feedExists(emailId: event.emailId, type: actionType.rawValue, contactId: "\(event.from)\(Constants.domain)"),
            let contact = DBManager.getContact("\(event.from)\(Constants.domain)"),
            let email = DBManager.getMail(key: event.emailId) else {
            finishCallback(true, nil)
            return
        }
        DBManager.updateEmail(email, status: Email.Status(rawValue: event.type) ?? .none)
        guard event.type == Email.Status.opened.rawValue else {
            finishCallback(true, nil)
            return
        }
        let open = FeedItem()
        open.fileId = event.fileId
        open.date = event.date
        open.email = email
        open.contact = contact
        open.id = open.incrementID()
        DBManager.store(open)
        finishCallback(true, open)
    }
    
    func handlePeerEmailStatusCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.EmailStatus.init(params: params)
        guard event.type != Email.Status.unsent.rawValue else {
            handleOpenEmailCommand(params: params, finishCallback: finishCallback)
            return
        }
        finishCallback(true, nil)
    }
    
    func handleAttachment(_ attachment: [String: Any], email: Email) -> File {
        let file = File()
        file.token = attachment["token"] as! String
        file.size = attachment["size"] as! Int
        file.name = attachment["name"] as! String
        file.mimeType = mimeTypeForPath(path: file.name)
        file.date = email.date
        file.readOnly = attachment["read_only"] as? Int ?? 0
        file.emailId = email.key
        DBManager.store(file)
        return file
    }
    
    func isMeARecipient(email: Email) -> Bool {
        let accountEmail = "\(myAccount.username)\(Constants.domain)"
        let bccContacts = Array(email.getContacts(type: .bcc))
        let ccContacts = Array(email.getContacts(type: .cc))
        let toContacts = Array(email.getContacts(type: .to))
        return bccContacts.contains(where: {$0.email == accountEmail})
            || ccContacts.contains(where: {$0.email == accountEmail})
            || toContacts.contains(where: {$0.email == accountEmail})
    }
    
    func isFromMe(email: Email) -> Bool {
        let accountEmail = "\(myAccount.username)\(Constants.domain)"
        return accountEmail == email.fromContact.email
    }
}

enum Event: Int32 {
    case newEmail = 1
    case openEmail = 2
    case peerEmailStatus = 3
}
