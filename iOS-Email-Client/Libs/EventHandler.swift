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
        default:
            break
        }
    }
    
    func handleNewEmailCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ email: Email?) -> Void){
        let threadId = params["threadId"] as! String
        let subject = params["subject"] as! String
        let from = params["from"] as! String
        let to = params["to"] as! String
        let cc = params["cc"] as! String
        let bcc = params["bcc"] as! String
        let messageId = params["messageId"] as! String
        let date = params["date"] as! String
        let metadataKey = params["metadataKey"] as! Int32
        let senderDeviceId = params["senderDeviceId"] as? Int32
        let messageType = MessageType.init(rawValue: (params["messageType"] as? Int ?? MessageType.none.rawValue))!
        let files = params["files"] as? [[String: Any]]
        
        let dateFormatter = DateFormatter()
        let timeZone = NSTimeZone(abbreviation: "UTC")
        dateFormatter.timeZone = timeZone as TimeZone?
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let localDate = dateFormatter.date(from: date) ?? Date()
        
        if let email = DBManager.getMailByKey(key: metadataKey.description) {
            if(isMeARecipient(email: email)){
                DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.inbox.id], removedLabelIds: [])
                finishCallback(true, email)
                return
            }
            finishCallback(true, nil)
            return
        }
        
        let email = Email()
        email.threadId = threadId
        email.subject = subject
        email.key = metadataKey.description
        email.messageId = messageId
        email.date = localDate
        email.unread = true
        
        if let attachments = files {
            for attachment in attachments {
                let file = handleAttachment(attachment, email: email)
                email.files.append(file)
            }
        }
        
        apiManager.getEmailBody(messageId: email.messageId, token: myAccount.jwt) { (error, data) in
            guard error == nil,
                let username = Utils.getUsernameFromEmailFormat(from),
                let content = self.handleBodyByMessageType(messageType, body: data as! String, recipientId: username, senderDeviceId: senderDeviceId) else {
                finishCallback(false, nil)
                return
            }
            email.content = content
            email.preview = String(email.content.removeHtmlTags().prefix(100))
            DBManager.store(email)
            
            ContactUtils.parseEmailContacts(from, email: email, type: .from)
            ContactUtils.parseEmailContacts(to, email: email, type: .to)
            ContactUtils.parseEmailContacts(cc, email: email, type: .cc)
            ContactUtils.parseEmailContacts(bcc, email: email, type: .bcc)
            
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
    
    func handleOpenEmailCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ open: FeedItem?) -> Void){
        let emailId = String(params["metadataKey"] as! Int)
        let from = params["from"] as! String
        let fileId = params["file"] as? String
        let date = params["date"] as! String
        
        guard from != myAccount.username else {
            finishCallback(true, nil)
            return
        }
        
        let open = FeedItem()
        open.fileId = fileId
        open.date = Utils.getLocalDate(from: date)
        guard !DBManager.feedExists(emailId: emailId, type: open.type, contactId: "\(from)\(Constants.domain)"),
            let contact = DBManager.getContact("\(from)\(Constants.domain)"),
            let email = DBManager.getMail(key: emailId) else {
            finishCallback(true, nil)
            return
        }
        open.email = email
        open.contact = contact
        open.id = open.incrementID()
        DBManager.updateEmail(email, status: .opened)
        DBManager.store(open)
        finishCallback(true, open)
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
}
