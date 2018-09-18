//
//  EventHandler.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftSoup

protocol EventHandlerDelegate {
    func didReceiveEvents(result: EventData.Result)
}

class EventHandler {
    let myAccount : Account
    var eventDelegate : EventHandlerDelegate?
    var apiManager : APIManager.Type = APIManager.self
    var signalHandler: SignalHandler.Type = SignalHandler.self
    
    init(account: Account){
        myAccount = account
    }

    func handleEvents(events: [[String: Any]]){
        var result = EventData.Result()
        var successfulEvents = [Int32]()
        handleEventsRecursive(events: events, index: 0, eventCallback: { (successfulEventId, data) in
            guard let eventId = successfulEventId else {
                return
            }
            successfulEvents.append(eventId)
            switch(data){
            case is Email:
                result.emails.append(data as! Email)
            case is FeedItem:
                result.opens.append(data as! FeedItem)
            case is [String]:
                result.modifiedThreadIds.append(contentsOf: data as! [String])
            case is [Int]:
                result.modifiedEmailKeys.append(contentsOf: data as! [Int])
            default:
                break
            }
        }) {
            if(!successfulEvents.isEmpty && !result.removed){
                self.apiManager.acknowledgeEvents(eventIds: successfulEvents, token: self.myAccount.jwt)
            }
            self.eventDelegate?.didReceiveEvents(result: result)
        }
    }
    
    func handleEventsRecursive(events: [[String: Any]], index: Int, eventCallback: @escaping (_ successfulEventId : Int32?, _ data: Any?) -> Void , finishCallback: @escaping () -> Void){
        if(events.count == index){
            finishCallback()
            return
        }
        let event = events[index]
        handleEvent(event) { (successfulEventId, data) in
            eventCallback(successfulEventId, data)
            self.handleEventsRecursive(events: events, index: index + 1, eventCallback: eventCallback, finishCallback: finishCallback)
        }
    }
    
    func handleEvent(_ event: Dictionary<String, Any>, finishCallback: @escaping (_ successfulEventId : Int32?, _ data: Any?) -> Void){
        let cmd = event["cmd"] as! Int32
        let rowId = event["rowid"] as? Int32 ?? -1
        
        guard let params = event["params"] as? [String : Any] ?? Utils.convertToDictionary(text: (event["params"] as! String)) else {
            finishCallback(nil, nil)
            return
        }
        
        func handleEventResponse(successfulEvent: Bool, item: Any?){
            guard successfulEvent else {
                    finishCallback(nil, nil)
                    return
            }
            finishCallback(rowId, item)
        }
        
        switch(cmd){
        case Event.newEmail.rawValue:
            self.handleNewEmailCommand(params: params, finishCallback: handleEventResponse)
            break
        case Event.emailStatus.rawValue:
            self.handleEmailStatusCommand(params: params, finishCallback: handleEventResponse)
            break
        case Event.Peer.unsent.rawValue:
            var fakeParams = params
            fakeParams["from"] = myAccount.username
            fakeParams["type"] = Email.Status.unsent.rawValue
            fakeParams["date"] = Date().description
            self.handlePeerUnsentCommand(params: fakeParams, finishCallback: handleEventResponse)
            break
        case Event.Peer.emailsUnread.rawValue:
            handleEmailUnreadCommand(params: params, finishCallback: handleEventResponse)
        case Event.Peer.threadsUnread.rawValue:
            handleThreadUnreadCommand(params: params, finishCallback: handleEventResponse)
        case Event.Peer.emailsLabels.rawValue:
            handleEmailChangeLabelsCommand(params: params, finishCallback: handleEventResponse)
        case Event.Peer.threadsLabels.rawValue:
            handleThreadChangeLabelsCommand(params: params, finishCallback: handleEventResponse)
        case Event.Peer.emailsDeleted.rawValue:
            handleEmailDeleteCommand(params: params, finishCallback: handleEventResponse)
        case Event.Peer.threadsDeleted.rawValue:
            handleThreadDeleteCommand(params: params, finishCallback: handleEventResponse)
        case Event.Peer.newLabel.rawValue:
            handleCreateLabelCommand(params: params, finishCallback: handleEventResponse)
        case Event.Peer.changeName.rawValue:
            handleChangeNameCommand(params: params, finishCallback: handleEventResponse)
        case Event.serverError.rawValue:
            handleEventResponse(successfulEvent: true, item: nil)
        case Event.Link.removed.rawValue:
            handleEventResponse(successfulEvent: true, item: true)
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
        
        apiManager.getEmailBody(metadataKey: email.key, token: myAccount.jwt) { (responseData) in
            var error: CriptextError?
            var unsent = false
            if case let .Error(err) = responseData {
                error = err
            }
            if case .Missing = responseData {
                unsent = true
            }
            
            guard (unsent || error == nil),
                let username = Utils.getUsernameFromEmailFormat(event.from),
                case let .SuccessString(body) = responseData,
                let content = unsent ? "" : self.handleBodyByMessageType(event.messageType, body: body, recipientId: username, senderDeviceId: event.senderDeviceId) else {
                finishCallback(false, nil)
                return
            }
            let contentPreview = self.getContentPreview(content: content)
            email.content = contentPreview.1
            email.preview = contentPreview.0
            if(unsent){
                email.unsentDate = email.date
                email.status = .unsent
            }
            DBManager.store(email, update: !unsent)
            
            if !unsent,
                let keyString = event.fileKey,
                let fileKeyString = self.handleBodyByMessageType(event.messageType, body: keyString, recipientId: username, senderDeviceId: event.senderDeviceId) {
                let fKey = FileKey()
                fKey.emailId = email.key
                fKey.key = fileKeyString
                DBManager.store([fKey])
            }
            
            ContactUtils.parseEmailContacts([event.from], email: email, type: .from)
            ContactUtils.parseEmailContacts(event.to, email: email, type: .to)
            ContactUtils.parseEmailContacts(event.cc, email: email, type: .cc)
            ContactUtils.parseEmailContacts(event.bcc, email: email, type: .bcc)
            
            if(self.isFromMe(email: email)){
                DBManager.updateEmail(email, status: .sent)
                DBManager.updateEmail(email, unread: false)
                DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.sent.id], removedLabelIds: [])
            }
            if(self.isMeARecipient(email: email)){
                DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.inbox.id], removedLabelIds: [])
            }
            if(!event.labels.isEmpty){
                let labels = event.labels.map({ (labelName) -> Int in
                    return SystemLabel.fromText(text: labelName)
                })
                DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: labels, removedLabelIds: [])
            }
            finishCallback(true, email)
        }
    }
    
    func getContentPreview(content: String) -> (String, String) {
        do {
            let allowList = try SwiftSoup.Whitelist.relaxed().addTags("style", "title", "header").addAttributes(":all", "class", "style")
            let doc: Document = try SwiftSoup.parse(content)
            let preview = try String(doc.text().prefix(100))
            let cleanContent = try SwiftSoup.clean(content, allowList)!
            return (preview, cleanContent)
        } catch {
            let preview = String(content.removeHtmlTags().replaceNewLineCharater(separator: " ").prefix(100))
            return (preview, content)
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
    
    func handleEmailStatusCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
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
    
    func handleSocketEvent(event: [String: Any]) -> EventData.Socket {
        let cmd = event["cmd"] as! Int32
        
        switch(cmd){
        case Event.Peer.passwordChange.rawValue:
            return .PasswordChange
        case Event.Link.removed.rawValue:
            return .Logout
        case Event.Peer.recoveryChange.rawValue:
            guard let params = event["params"] as? [String: Any],
                let address = params["address"] as? String else {
                return .Error
            }
            return .RecoveryChanged(address)
        case Event.Peer.recoveryVerify.rawValue:
            return .RecoveryVerified
        case Event.newEvent.rawValue:
            return .NewEvent
        default:
            return .Unhandled
        }
    }
}

extension EventHandler {
    func handleEmailUnreadCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.Peer.EmailUnread.init(params: params)
        DBManager.markAsUnread(emailKeys: event.metadataKeys, unread: event.unread)
        finishCallback(true, event.metadataKeys)
    }
    
    func handleThreadUnreadCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.Peer.ThreadUnread.init(params: params)
        DBManager.markAsUnread(threadIds: event.threadIds, unread: event.unread)
        finishCallback(true, event.threadIds)
    }
    
    func handleEmailChangeLabelsCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.Peer.EmailLabels.init(params: params)
        DBManager.addRemoveLabels(emailKeys: event.metadataKeys, addedLabelNames: event.labelsAdded, removedLabelNames: event.labelsRemoved)
        finishCallback(true, event.metadataKeys)
    }
    
    func handleThreadChangeLabelsCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.Peer.ThreadLabels.init(params: params)
        DBManager.addRemoveLabels(threadIds: event.threadIds, addedLabelNames: event.labelsAdded, removedLabelNames: event.labelsRemoved)
        finishCallback(true, event.threadIds)
    }
    
    func handleEmailDeleteCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.Peer.EmailDeleted.init(params: params)
        DBManager.deleteEmails(emailKeys: event.metadataKeys)
        finishCallback(true, event.metadataKeys)
    }
    
    func handleThreadDeleteCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.Peer.ThreadDeleted.init(params: params)
        DBManager.deleteThreads(threadIds: event.threadIds)
        finishCallback(true, event.threadIds)
    }
    
    func handlePeerUnsentCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.EmailStatus.init(params: params)
        guard event.type != Email.Status.unsent.rawValue else {
            handleEmailStatusCommand(params: params, finishCallback: finishCallback)
            return
        }
        finishCallback(true, [event.emailId])
    }
    
    func handleCreateLabelCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.Peer.NewLabel.init(params: params)
        let label = Label()
        label.text = event.text
        label.color = event.color
        DBManager.store(label, incrementId: true)
        finishCallback(true, nil)
    }
    
    func handleChangeNameCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Any?) -> Void){
        let event = EventData.Peer.NameChanged.init(params: params)
        DBManager.update(account: myAccount, name: event.name)
        finishCallback(true, nil)
    }
}

enum Event: Int32 {
    case newEmail = 101
    case emailStatus = 102
    case serverError = 104
    case newEvent = 400
    
    enum Link: Int32 {
        case removed = 205
    }
    
    enum Peer: Int32 {
        case emailsUnread = 301
        case threadsUnread = 302
        case emailsLabels = 303
        case threadsLabels = 304
        case emailsDeleted = 305
        case threadsDeleted = 306
        case unsent = 307
        case newLabel = 308
        case changeName = 309
        case passwordChange = 310
        case recoveryChange = 311
        case recoveryVerify = 312
    }
}
