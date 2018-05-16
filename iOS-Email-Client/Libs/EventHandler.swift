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
}

class EventHandler {
    let myAccount : Account
    var eventDelegate : EventHandlerDelegate?
    var emails = [Email]()
    var successfulEvents = [Int32]()
    
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
                APIManager.acknowledgeEvents(eventIds: self.successfulEvents, token: self.myAccount.jwt)
            }
            guard !self.emails.isEmpty else {
                return
            }
            self.eventDelegate?.didReceiveNewEmails(emails: self.emails)
            self.emails.removeAll()
            self.successfulEvents.removeAll()
        }
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
        let messageType = params["messageType"] as! Int
        
        let dateFormatter = DateFormatter()
        let timeZone = NSTimeZone(abbreviation: "UTC")
        dateFormatter.timeZone = timeZone as TimeZone?
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let localDate = dateFormatter.date(from: date) ?? Date()
        
        guard DBManager.getMailByKey(key: metadataKey.description) == nil else {
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
        
        APIManager.getEmailBody(messageId: email.messageId, token: myAccount.jwt) { (error, data) in
            guard error == nil,
                let username = Utils.getUsernameFromEmailFormat(from) else {
                finishCallback(false)
                return
            }
            let signalMessage = data as! String
            email.content = SignalHandler.decryptMessage(signalMessage, messageType: messageType, account: self.myAccount, recipientId: username, deviceId: senderDeviceId)
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
}

enum Event: Int32 {
    case newEmail = 1
}
