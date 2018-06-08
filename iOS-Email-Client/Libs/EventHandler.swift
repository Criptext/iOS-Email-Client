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
    func didReceiveOpens(opens: [Open])
}

class EventHandler {
    let myAccount : Account
    var eventDelegate : EventHandlerDelegate?
    var emails = [Email]()
    var opens = [Open]()
    var successfulEvents = [Int32]()
    var apiManager : APIManager.Type = APIManager.self
    var signalHandler: SignalHandler.Type = SignalHandler.self
    
    init(account: Account){
        myAccount = account
    }
    
    func handleEvents(events: Array<Dictionary<String, Any>>){
        let asyncGroupCalls = DispatchGroup()
        events.forEach({ (event) in
            asyncGroupCalls.enter()
            self.handleEvent(event){
                asyncGroupCalls.leave()
            }
        })
        asyncGroupCalls.notify(queue: .main) {
            if(!self.successfulEvents.isEmpty){
                self.apiManager.acknowledgeEvents(eventIds: self.successfulEvents, token: self.myAccount.jwt)
            }
            self.checkForEmails()
            self.checkForOpens()
            self.successfulEvents.removeAll()
        }
    }
    
    func checkForEmails(){
        guard !self.emails.isEmpty else {
            return
        }
        self.eventDelegate?.didReceiveNewEmails(emails: self.emails)
        self.emails.removeAll()
    }
    
    func checkForOpens(){
        guard !self.opens.isEmpty else {
            return
        }
        self.eventDelegate?.didReceiveOpens(opens: self.opens)
        self.opens.removeAll()
    }
    
    func handleEvent(_ event: Dictionary<String, Any>, finishCallback: @escaping () -> Void){
        let cmd = event["cmd"] as! Int32
        let rowId = event["rowid"] as? Int32
        guard let params = event["params"] as? [String : Any] ?? Utils.convertToDictionary(text: (event["params"] as! String)) else {
            return
        }
        switch(cmd){
        case Event.newEmail.rawValue:
            self.handleNewEmailCommand(params: params){ successfulEvent in
                if successfulEvent,
                    let eventId = rowId {
                    self.successfulEvents.append(eventId)
                }
                finishCallback()
            }
            break
        case Event.openEmail.rawValue:
            self.handleOpenEmailCommand(params: params){ successfulEvent in
                if successfulEvent,
                    let eventId = rowId {
                    self.successfulEvents.append(eventId)
                }
                finishCallback()
            }
            break
        default:
            break
        }
    }
    
    func handleNewEmailCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool) -> Void){
        let threadId = params["threadId"] as! String
        let subject = params["subject"] as! String
        let from = params["from"] as! String
        let to = params["to"] as! String
        let cc = params["cc"] as! String
        let bcc = params["bcc"] as! String
        let messageId = params["messageId"] as! String
        let date = params["date"] as! String
        let metadataKey = params["metadataKey"] as! Int32
        let senderDeviceId = params["senderDeviceId"] as! Int32
        let messageType = MessageType.init(rawValue: (params["messageType"] as! Int))!
        let files = params["files"] as? [[String: Any]]
        
        let dateFormatter = DateFormatter()
        let timeZone = NSTimeZone(abbreviation: "UTC")
        dateFormatter.timeZone = timeZone as TimeZone?
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let localDate = dateFormatter.date(from: date) ?? Date()
        
        if let email = DBManager.getMailByKey(key: metadataKey.description) {
            if(email.labels.count == 1 && email.labels.first!.id == SystemLabel.sent.id){
                DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.inbox.id], removedLabelIds: [])
                self.emails.append(email)
            }
            finishCallback(true)
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
                handleAttachment(attachment, email: email)
            }
        }
        
        apiManager.getEmailBody(messageId: email.messageId, token: myAccount.jwt) { (error, data) in
            guard error == nil,
                let username = Utils.getUsernameFromEmailFormat(from) else {
                finishCallback(false)
                return
            }
            let signalMessage = data as! String
            let exception = tryBlock {
                email.content = self.signalHandler.decryptMessage(signalMessage, messageType: messageType, account: self.myAccount, recipientId: username, deviceId: senderDeviceId)
            }
            guard exception == nil else {
                finishCallback(false)
                return
            }
            email.preview = String(email.content.removeHtmlTags().prefix(100))
            email.labels.append(DBManager.getLabel(SystemLabel.inbox.id)!)
            DBManager.store(email)
            self.emails.append(email)
            
            ContactManager.parseEmailContacts(from, email: email, type: .from)
            ContactManager.parseEmailContacts(to, email: email, type: .to)
            ContactManager.parseEmailContacts(cc, email: email, type: .cc)
            ContactManager.parseEmailContacts(bcc, email: email, type: .bcc)
            finishCallback(true)
        }
    }
    
    func handleOpenEmailCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool) -> Void){
        let type = params["type"] as! Int
        let emailId = String(params["metadataKey"] as! Int)
        let from = params["from"] as! String
        let fileId = params["file"] as? String
        let date = params["date"] as! String
        
        let open = Open()
        open.contactId = from
        open.emailId = emailId
        open.type = type
        open.fileId = fileId
        open.date = Utils.getLocalDate(from: date)
        guard !DBManager.openExists(emailId: emailId, type: type, contactId: from) else {
            finishCallback(true)
            return
        }
        open.id = open.incrementID()
        DBManager.store(open)
        opens.append(open)
        finishCallback(true)
    }
    
    func handleAttachment(_ attachment: [String: Any], email: Email) {
        let file = File()
        file.token = attachment["token"] as! String
        file.size = attachment["size"] as! Int
        file.name = attachment["name"] as! String
        file.mimeType = mimeTypeForPath(path: file.name)
        file.date = email.date
        file.readOnly = attachment["read_only"] as? Int ?? 0
        file.emailId = email.key
        DBManager.store(file)
        email.files.append(file)
    }
}

enum Event: Int32 {
    case newEmail = 1
    case openEmail = 2
}
