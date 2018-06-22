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
                let username = Utils.getUsernameFromEmailFormat(from) else {
                finishCallback(false, nil)
                return
            }
            let signalMessage = data as! String
            let exception = tryBlock {
                email.content = self.signalHandler.decryptMessage(signalMessage, messageType: messageType, account: self.myAccount, recipientId: username, deviceId: senderDeviceId)
            }
            guard exception == nil else {
                finishCallback(false, nil)
                return
            }
            email.preview = String(email.content.removeHtmlTags().prefix(100))
            email.labels.append(DBManager.getLabel(SystemLabel.inbox.id)!)
            DBManager.store(email)
            
            ContactManager.parseEmailContacts(from, email: email, type: .from)
            ContactManager.parseEmailContacts(to, email: email, type: .to)
            ContactManager.parseEmailContacts(cc, email: email, type: .cc)
            ContactManager.parseEmailContacts(bcc, email: email, type: .bcc)
            finishCallback(true, email)
        }
    }
    
    func handleOpenEmailCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ open: FeedItem?) -> Void){
        let emailId = String(params["metadataKey"] as! Int)
        let from = params["from"] as! String
        let fileId = params["file"] as? String
        let date = params["date"] as! String
        
        let open = FeedItem()
        open.fileId = fileId
        open.isNew = true
        open.date = Utils.getLocalDate(from: date)
        guard !DBManager.feedExists(emailId: emailId, type: open.type, contactId: "\(from)@jigl.com"),
            let contact = DBManager.getContact("\(from)@jigl.com"),
            let email = DBManager.getMail(key: emailId) else {
            finishCallback(true, nil)
            return
        }
        open.email = email
        open.contact = contact
        open.id = open.incrementID()
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
}

enum Event: Int32 {
    case newEmail = 1
    case openEmail = 2
}
