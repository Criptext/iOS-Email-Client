//
//  EventHandler.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftSoup

class EventHandler {
    let username : String
    let jwt: String
    var apiManager : APIManager.Type = APIManager.self
    var signalHandler: SignalHandler.Type = SignalHandler.self
    let queue = DispatchQueue.global(qos: .default)
    var parsedKeys = false
    
    init(account: Account){
        username = account.username
        jwt = account.jwt
    }

    func handleEvents(events: [[String: Any]], completion: @escaping (_ result: EventData.Result) -> Void){
        var result = EventData.Result()
        var successfulEvents = [Int32]()
        let dispatchQueue = DispatchQueue(label: "taskQueue")
        let dispatchSemaphore = DispatchSemaphore(value: 0)
        
        dispatchQueue.async {
            for (index, event) in events.enumerated() {
                self.handleEvent(event, finishCallback: { (successfulEventId, eventResult) in
                    self.handleEventResult(result: &result, successfulEvents: &successfulEvents , successfulEventId, eventResult)
                    dispatchSemaphore.signal()
                    guard index == events.count - 1 else {
                        return
                    }
                    DispatchQueue.main.async {
                        if(!successfulEvents.isEmpty && !result.removed){
                            self.apiManager.acknowledgeEvents(eventIds: successfulEvents, token: self.jwt)
                        }
                        completion(result)
                    }
                })
                dispatchSemaphore.wait()
            }
        }
    }
    
    func handleEventResult(result: inout EventData.Result, successfulEvents: inout [Int32], _ successfulEventId : Int32?, _ eventResult: Event.EventResult) {
        guard let eventId = successfulEventId else {
            return
        }
        successfulEvents.append(eventId)
        switch(eventResult){
        case .Email(let email):
            result.emailLabels.append(contentsOf: Array(email.labels.map({$0.text})))
        case .Feed(let open):
            result.opens.append(open.email.threadId)
        case .ModifiedThreads(let threads):
            result.modifiedThreadIds.append(contentsOf: threads)
        case .ModifiedEmails(let emails):
            result.modifiedEmailKeys.append(contentsOf: emails)
        case .NameChanged, .LabelCreated:
            result.updateSideMenu = true
        case .LinkData(let linkData):
            result.linkStartData = linkData
        case .News(let feature):
            result.feature = feature
        default:
            break
        }
    }
    
    func handleEvent(_ event: [String: Any], finishCallback: @escaping (_ successfulEventId : Int32?, _ data: Event.EventResult) -> Void){
        let cmd = event["cmd"] as! Int32
        let rowId = event["rowid"] as? Int32 ?? -1
        guard let params = event["params"] as? [String : Any] ?? Utils.convertToDictionary(text: (event["params"] as! String)) else {
            finishCallback(nil, .Empty)
            return
        }
        func handleEventResponse(successfulEvent: Bool, result: Event.EventResult){
            guard successfulEvent else {
                    finishCallback(nil, .Empty)
                    return
            }
            finishCallback(rowId, result)
        }
        DBManager.refresh()
        switch(cmd){
        case Event.newEmail.rawValue:
            self.handleNewEmailCommand(params: params, finishCallback: handleEventResponse)
        case Event.emailStatus.rawValue:
            self.handleEmailStatusCommand(params: params, finishCallback: handleEventResponse)
        case Event.preKeys.rawValue:
            self.handlePreKeysCommand(finishCallback: handleEventResponse)
        case Event.Peer.unsent.rawValue:
            var fakeParams = params
            fakeParams["from"] = self.username
            fakeParams["type"] = Email.Status.unsent.rawValue
            fakeParams["date"] = Date().description
            self.handlePeerUnsentCommand(params: fakeParams, finishCallback: handleEventResponse)
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
        case Event.Peer.updateProfilePic.rawValue:
            handleUpdateProfilePic(params: params, finishCallback: handleEventResponse)
        case Event.Server.news.rawValue:
            handleNewsCommand(params: params, finishCallback: handleEventResponse)
        case Event.serverError.rawValue:
            handleEventResponse(successfulEvent: true, result: .Empty)
        case Event.Link.start.rawValue:
            guard let linkData = LinkData.fromDictionary(params, kind: .link) else {
                handleEventResponse(successfulEvent: true, result: .Empty)
                break
            }
            handleEventResponse(successfulEvent: true, result: .LinkData(linkData))
        case Event.Sync.start.rawValue:
            guard let linkData = LinkData.fromDictionary(params, kind: .sync) else {
                handleEventResponse(successfulEvent: true, result: .Empty)
                break
            }
            handleEventResponse(successfulEvent: true, result: .LinkData(linkData))
        case Event.Link.success.rawValue:
            finishCallback(rowId, .Empty)
        default:
            finishCallback(nil, .Empty)
            break
        }
    }
    
    func handleNewEmailCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ email: Event.EventResult) -> Void){
        let handler = NewEmailHandler(username: self.username, queue: self.queue)
        handler.api = self.apiManager
        handler.signal = self.signalHandler
        handler.command(params: params) { (result) in
            guard let email = result.email else {
                finishCallback(result.success, .Empty)
                return
            }
            finishCallback(result.success, .Email(email))
        }
    }
    
    func handlePreKeysCommand(finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void) {
        guard !parsedKeys else {
            finishCallback(true, .Empty)
            return
        }
        guard let myAccount = DBManager.getAccountByUsername(self.username) else {
            finishCallback(false, .Empty)
            return
        }
        let bundle = CRBundle(account: myAccount)
        guard let keys = bundle.generatePreKeys() else {
            finishCallback(false, .Empty)
            return
        }
        
        APIManager.postKeys(keys, account: myAccount) { (responseData) in
            guard case .Success = responseData else {
                finishCallback(false, .Empty)
                return
            }
            self.parsedKeys = true
            finishCallback(true, .Empty)
        }
    }
    
    func handleEmailStatusCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        guard let myAccount = DBManager.getAccountByUsername(self.username) else {
            finishCallback(false, .Empty)
            return
        }
        let event = EventData.EmailStatus.init(params: params)
        if event.type == Email.Status.unsent.rawValue {
            guard let email = DBManager.getMail(key: event.emailId, account: myAccount),
                let myAccount = DBManager.getAccountByUsername(self.username) else {
                finishCallback(false, .Empty)
                return
            }
            FileUtils.deleteDirectoryFromEmail(account: myAccount, metadataKey: "\(email.key)")
            DBManager.unsendEmail(email, date: event.date)
            finishCallback(true, .Email(email))
            return
        }
        let actionType: FeedItem.Action = event.fileId == nil ? .open : .download
        guard !DBManager.feedExists(emailId: event.emailId, type: actionType.rawValue, contactId: "\(event.from)\(Constants.domain)"),
            let contact = DBManager.getContact("\(event.from)\(Constants.domain)"),
            let email = DBManager.getMail(key: event.emailId, account: myAccount) else {
            finishCallback(true, .Empty)
            return
        }
        DBManager.updateEmail(email, status: Email.Status(rawValue: event.type) ?? .none)
        guard event.type == Email.Status.opened.rawValue else {
            finishCallback(true, .Empty)
            return
        }
        let open = FeedItem()
        open.fileId = event.fileId
        open.date = event.date
        open.email = email
        open.contact = contact
        open.id = open.incrementID()
        DBManager.store(open)
        finishCallback(true, .Feed(open))
    }
    
    func handleSocketEvent(event: [String: Any]) -> EventData.Socket {
        guard let cmd = event["cmd"] as? Int32 else {
            return .Unhandled
        }
        
        switch(cmd){
        case Event.Sync.start.rawValue:
            guard let params = event["params"] as? [String: Any],
                let linkData = LinkData.fromDictionary(params, kind: .sync) else {
                return .Error
            }
            return .LinkData(linkData)
        case Event.Sync.accept.rawValue:
            guard let params = event["params"] as? [String: Any],
                let syncData = AcceptData.fromDictionary(params) else {
                    return .Error
            }
            return .SyncAccept(syncData)
        case Event.Sync.deny.rawValue:
            return .SyncDeny
        case Event.Link.start.rawValue:
            guard let params = event["params"] as? [String: Any],
                let linkData = LinkData.fromDictionary(params, kind: .link) else {
                    return .Error
            }
            return .LinkData(linkData)
        case Event.Peer.passwordChange.rawValue:
            return .PasswordChange
        case Event.Link.removed.rawValue:
            return .Logout
        case Event.Link.bundle.rawValue:
            guard let params = event["params"] as? [String: Any],
                let deviceId = params["deviceId"] as? Int32 else {
                    return .Error
            }
            return .KeyBundle(deviceId)
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
    func handleEmailUnreadCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.EmailUnread.init(params: params)
        DBManager.markAsUnread(emailKeys: event.metadataKeys, unread: event.unread)
        finishCallback(true, .ModifiedEmails(event.metadataKeys))
    }
    
    func handleThreadUnreadCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.ThreadUnread.init(params: params)
        DBManager.markAsUnread(threadIds: event.threadIds, unread: event.unread)
        finishCallback(true, .ModifiedThreads(event.threadIds))
    }
    
    func handleEmailChangeLabelsCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.EmailLabels.init(params: params)
        DBManager.addRemoveLabels(emailKeys: event.metadataKeys, addedLabelNames: event.labelsAdded, removedLabelNames: event.labelsRemoved)
        finishCallback(true, .ModifiedEmails(event.metadataKeys))
    }
    
    func handleThreadChangeLabelsCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.ThreadLabels.init(params: params)
        DBManager.addRemoveLabels(threadIds: event.threadIds, addedLabelNames: event.labelsAdded, removedLabelNames: event.labelsRemoved)
        finishCallback(true, .ModifiedThreads(event.threadIds))
    }
    
    func handleEmailDeleteCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.EmailDeleted.init(params: params)
        DBManager.deleteEmails(emailKeys: event.metadataKeys)
        finishCallback(true, .ModifiedEmails(event.metadataKeys))
    }
    
    func handleThreadDeleteCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.ThreadDeleted.init(params: params)
        DBManager.deleteThreads(threadIds: event.threadIds)
        finishCallback(true, .ModifiedThreads(event.threadIds))
    }
    
    func handlePeerUnsentCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.EmailStatus.init(params: params)
        guard event.type != Email.Status.unsent.rawValue else {
            handleEmailStatusCommand(params: params, finishCallback: finishCallback)
            return
        }
        finishCallback(true, .ModifiedEmails([event.emailId]))
    }
    
    func handleCreateLabelCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        guard let myAccount = DBManager.getAccountByUsername(self.username) else {
            finishCallback(false, .Empty)
            return
        }
        let event = EventData.Peer.NewLabel.init(params: params)
        let label = Label()
        label.text = event.text
        label.color = event.color
        label.account = myAccount
        DBManager.store(label, incrementId: true)
        finishCallback(true, .LabelCreated)
    }
    
    func handleChangeNameCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        guard let myAccount = DBManager.getAccountByUsername(self.username) else {
            finishCallback(false, .Empty)
            return
        }
        let event = EventData.Peer.NameChanged.init(params: params)
        DBManager.update(account: myAccount, name: event.name)
        finishCallback(true, .NameChanged)
    }
    
    func handleUpdateProfilePic(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        UIUtils.deleteSDWebImageCache()
        finishCallback(true, .UpdateProfilePic)
    }
    
    func handleNewsCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Server.News(params: params)
        APIManager.getNews(code: event.code) { (responseData) in
            guard case let .SuccessDictionary(news) = responseData,
                let title = news["title"] as? String,
                let body = news["body"] as? String,
                let imageUrl = news["imageUrl"] as? String else {
                    finishCallback(false, .Empty)
                return
            }
            let feature = MailboxData.Feature(imageUrl: imageUrl, title: title, subtitle: body, version: event.version, symbol: Int(event.symbol))
            finishCallback(true, .News(feature))
        }
    }
}

enum Event: Int32 {
    case newEmail = 101
    case emailStatus = 102
    case serverError = 104
    case preKeys = 107
    case newEvent = 400
    
    enum Link: Int32 {
        case start = 201
        case accept = 202
        case bundle = 203
        case success = 204
        case removed = 205
        case deny = 206
    }
    
    enum Sync: Int32 {
        case start = 211
        case accept = 212
        case deny = 216
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
        case updateProfilePic = 313
    }
    
    enum Server: Int32 {
        case news = 401
    }
    
    enum Queue: Int32 {
        case open = 500
    }
    
    enum EventResult {
        case LinkData(LinkData)
        case Email(Email)
        case Feed(FeedItem)
        case ModifiedThreads([String])
        case ModifiedEmails([Int])
        case NameChanged
        case LabelCreated
        case Empty
        case News(MailboxData.Feature)
        case UpdateProfilePic
    }
}
