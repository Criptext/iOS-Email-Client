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
    let accountId : String
    let jwt: String
    var apiManager : APIManager.Type = APIManager.self
    var signalHandler: SignalHandler.Type = SignalHandler.self
    let queue = DispatchQueue.global(qos: .userInteractive)
    var parsedKeys = false
    
    init(account: Account){
        accountId = account.compoundKey
        jwt = account.jwt
    }

    func handleEvents(events: [[String: Any]], completion: @escaping (_ result: EventData.Result) -> Void){
        var result = EventData.Result()
        var successfulEvents = [Any]()
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
    
    func handleEventResult(result: inout EventData.Result, successfulEvents: inout [Any], _ successfulEventId : Any?, _ eventResult: Event.EventResult) {
        
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
        case .NameChanged, .UpdateProfilePic, .LabelCreated, .LabelDeleted, .LabelEdited:
            result.updateSideMenu = true
        case .LinkData(let linkData):
            result.linkStartData = linkData
        case .News(let feature):
            result.feature = feature
        case .CustomerType(let newType):
            result.updateSideMenu = true
            result.newCustomerType = newType
        default:
            break
        }
    }
    
    func handleEvent(_ event: [String: Any], finishCallback: @escaping (_ successfulEventId : Any?, _ data: Event.EventResult) -> Void){
        let cmd = event["cmd"] as! Int32
        let rowId = event["rowid"] as? Int32 ?? -1
        let docId = event["docid"] as? String ?? nil
        guard let params = event["params"] as? [String : Any] ?? Utils.convertToDictionary(text: (event["params"] as! String)) else {
            finishCallback(nil, .Empty)
            return
        }
        func handleEventResponse(successfulEvent: Bool, result: Event.EventResult){
            guard successfulEvent else {
                    finishCallback(nil, .Empty)
                    return
            }
            if(docId != nil){
                finishCallback(docId, result)
            } else {
                finishCallback(rowId, result)
            }
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
            fakeParams["from"] = self.accountId.contains("@") ? String(accountId.split(separator: "@").first!) : accountId
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
        case Event.Peer.editLabel.rawValue:
            handleEditLabelCommand(params: params, finishCallback: handleEventResponse)
        case Event.Peer.deleteLabel.rawValue:
            handleDeleteLabelCommand(params: params, finishCallback: handleEventResponse)
        case Event.Peer.blockRemoteContent.rawValue:
            handleBlockRemoteContentCommand(params: params, finishCallback: handleEventResponse)
        case Event.Peer.contactTrust.rawValue:
            handleContactTrustCommand(params: params, finishCallback: handleEventResponse)
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
            if(docId != nil){
                finishCallback(docId, .Empty)
            } else {
                finishCallback(rowId, .Empty)
            }
        case Event.Acc.customerType.rawValue:
            handleAccountCustomerType(params: params, finishCallback: handleEventResponse)
        case Event.Peer.addressCreated.rawValue:
            handleAddressCreated(params: params, finishCallback: handleEventResponse)
        case Event.Peer.addressStatusUpdate.rawValue:
            handleAddressStatusUpdate(params: params, finishCallback: handleEventResponse)
        case Event.Peer.addressDeleted.rawValue:
            handleAddressDeleted(params: params, finishCallback: handleEventResponse)
        case Event.Peer.domainCreated.rawValue:
            handleDomainCreated(params: params, finishCallback: handleEventResponse)
        case Event.Peer.domainDeleted.rawValue:
            handleDomainDeleted(params: params, finishCallback: handleEventResponse)
        case Event.Peer.defaultUpdate.rawValue:
            handleDefaultUpdate(params: params, finishCallback: handleEventResponse)
        case Event.Peer.addressNameUpdate.rawValue:
            handleAddressNameUpdate(params: params, finishCallback: handleEventResponse)
        default:
            finishCallback(nil, .Empty)
            break
        }
    }
    
    func handleNewEmailCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ email: Event.EventResult) -> Void){
        let handler = NewEmailHandler(accountId: self.accountId, queue: self.queue)
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
        guard let myAccount = DBManager.getAccountById(self.accountId) else {
            finishCallback(false, .Empty)
            return
        }
        let bundle = CRBundle(account: myAccount)
        guard let keys = bundle.generatePreKeys() else {
            finishCallback(false, .Empty)
            return
        }
        
        APIManager.postKeys(keys, token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                finishCallback(false, .Empty)
                return
            }
            self.parsedKeys = true
            finishCallback(true, .Empty)
        }
    }
    
    func handleEmailStatusCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        guard let myAccount = DBManager.getAccountById(self.accountId) else {
            finishCallback(false, .Empty)
            return
        }
        let event = EventData.EmailStatus.init(params: params)
        if event.type == Email.Status.unsent.rawValue {
            guard let email = DBManager.getMail(key: event.emailId, account: myAccount),
                let myAccount = DBManager.getAccountById(self.accountId) else {
                finishCallback(false, .Empty)
                return
            }
            FileUtils.deleteDirectoryFromEmail(account: myAccount, metadataKey: "\(email.key)")
            DBManager.unsendEmail(email, date: event.date)
            finishCallback(true, .ModifiedEmails([email.key]))
            return
        }
        let actionType: FeedItem.Action = event.fileId == nil ? .open : .download
        guard !DBManager.feedExists(emailId: event.emailId, type: actionType.rawValue, contactId: event.from),
            let contact = DBManager.getContact(event.from),
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
        guard let myAccount = DBManager.getAccountById(self.accountId) else {
            finishCallback(false, .Empty)
            return
        }
        let event = EventData.Peer.NewLabel.init(params: params)
        let label = Label()
        label.text = event.text
        label.color = event.color
        label.uuid = event.uuid
        label.account = myAccount
        DBManager.store(label, incrementId: true)
        finishCallback(true, .LabelCreated)
    }
    
    func handleDeleteLabelCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        guard let myAccount = DBManager.getAccountById(self.accountId) else {
            finishCallback(false, .Empty)
            return
        }
        let event = EventData.Peer.DeleteLabel.init(params: params)
        DBManager.deleteLabelByUUID(uuid: event.uuid, account: myAccount)
        finishCallback(true, .LabelDeleted)
    }
    
    func handleBlockRemoteContentCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        guard let myAccount = DBManager.getAccountById(self.accountId) else {
            finishCallback(false, .Empty)
            return
        }
        let event = EventData.Peer.BlockContent.init(params: params)
        DBManager.update(account: myAccount, blockContent: event.block)
        finishCallback(true, .Empty)
    }
    
    func handleContactTrustCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.ContactTrust.init(params: params)
        guard let contact = DBManager.getContact(event.email) else {
            finishCallback(false, .Empty)
            return
        }
        DBManager.update(contact: contact, isTrusted: true)
        finishCallback(true, .Empty)
    }
    
    func handleEditLabelCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        guard let myAccount = DBManager.getAccountById(self.accountId) else {
            finishCallback(false, .Empty)
            return
        }
        let event = EventData.Peer.EditLabel.init(params: params)
        DBManager.updateLabelNameByUUID(uuid: event.uuid, newName: event.text, account: myAccount)
        finishCallback(true, .LabelEdited)
    }
    
    func handleChangeNameCommand(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        guard let myAccount = DBManager.getAccountById(self.accountId) else {
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
    
    func handleAccountCustomerType(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        UIUtils.deleteSDWebImageCache()
        let event = EventData.Acc.CustomerType.init(params: params)
        let recipientId = event.domain == Env.plainDomain ? event.recipientId : "\(event.recipientId)@\(event.domain)"
        guard let myAccount = DBManager.getAccountById(recipientId) else {
            finishCallback(true, .Empty)
            return
        }
        DBManager.update(account: myAccount, customerType: event.customerType)
        finishCallback(true, .CustomerType(event.customerType))
    }
    
    func handleAddressCreated(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.AddressCreated.init(params: params)
        guard let myAccount = DBManager.getAccountById(self.accountId),
            DBManager.getAlias(rowId: event.id, account: myAccount) == nil else {
            finishCallback(true, .Empty)
            return
        }
        let alias = Alias();
        alias.name = event.name
        alias.rowId = event.id
        alias.domain = event.domain == Env.plainDomain ? nil : event.domain
        alias.account = myAccount
        DBManager.store(alias)
        finishCallback(true, .Empty)
    }
    
    func handleAddressStatusUpdate(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.AddressStatusUpdate.init(params: params)
        guard let myAccount = DBManager.getAccountById(self.accountId),
            let existingAlias = DBManager.getAlias(rowId: event.id, account: myAccount) else {
            finishCallback(true, .Empty)
            return
        }
        DBManager.update(alias: existingAlias, active: event.active)
        finishCallback(true, .Empty)
    }
    
    func handleAddressDeleted(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.AddressDeleted.init(params: params)
        guard let myAccount = DBManager.getAccountById(self.accountId),
            let existingAlias = DBManager.getAlias(rowId: event.id, account: myAccount) else {
            finishCallback(true, .Empty)
            return
        }
        DBManager.deleteAlias(existingAlias)
        finishCallback(true, .Empty)
    }
    
    func handleDomainCreated(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.DomainCreated.init(params: params)
        guard let myAccount = DBManager.getAccountById(self.accountId),
            DBManager.getCustomDomain(name: event.name, account: myAccount) == nil else {
            finishCallback(true, .Empty)
            return
        }
        let customDomain = CustomDomain()
        customDomain.name = event.name
        customDomain.account = myAccount
        DBManager.store(customDomain)
        finishCallback(true, .Empty)
    }
    
    func handleDomainDeleted(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.DomainDelete.init(params: params)
        guard let myAccount = DBManager.getAccountById(self.accountId),
            let existingDomain = DBManager.getCustomDomain(name: event.name, account: myAccount) else {
            finishCallback(true, .Empty)
            return
        }
        DBManager.deleteAlias(existingDomain.name, account: myAccount)
        DBManager.deleteCustomDomain(existingDomain)
        finishCallback(true, .Empty)
    }
    
    func handleDefaultUpdate(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.DefaultUpdate.init(params: params)
        guard let myAccount = DBManager.getAccountById(self.accountId) else {
            finishCallback(true, .Empty)
            return
        }
        DBManager.update(account: myAccount, defaultAddressId: event.aliasId)
        finishCallback(true, .Empty)
    }
    
    func handleAddressNameUpdate(params: [String: Any], finishCallback: @escaping (_ successfulEvent: Bool, _ item: Event.EventResult) -> Void){
        let event = EventData.Peer.AddressNameUpdate.init(params: params)
        guard let myAccount = DBManager.getAccountById(self.accountId),
            let existingAlias = DBManager.getAlias(rowId: event.aliasId, account: myAccount) else {
            finishCallback(true, .Empty)
            return
        }
        if let contact = DBManager.getContact(existingAlias.email) {
            DBManager.update(contact: contact, name: event.name)
        } else {
            let newContact = Contact()
            newContact.displayName = event.name
            newContact.email = existingAlias.email
            newContact.isTrusted = true
            DBManager.store([newContact], account: myAccount)
        }
        finishCallback(true, .Empty)
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
    
    enum UserEvent: Int32 {
        case openComposer = 23
        case resumeApp = 24
    }
    
    enum Link: Int32 {
        case start = 201
        case accept = 202
        case bundle = 203
        case success = 204
        case removed = 205
        case deny = 206
        case dismiss = 207
    }
    
    enum Sync: Int32 {
        case start = 211
        case accept = 212
        case deny = 216
        case dismiss = 217
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
        case editLabel = 319
        case deleteLabel = 320
        
        case blockRemoteContent = 326
        case contactTrust = 327
        
        case addressCreated = 701
        case addressStatusUpdate = 702
        case addressDeleted = 703
        case domainCreated = 704
        case domainDeleted = 705
        case defaultUpdate = 706
        case addressNameUpdate = 707
    }
    
    enum Acc: Int32 {
        case customerType = 700
    }
    
    enum Server: Int32 {
        case news = 401
    }
    
    enum Queue: Int32 {
        case open = 500
    }
    
    enum Enterprise: Int32 {
        case accountSuspended = 600
        case accountUnsuspended = 601
    }
    
    enum EventResult {
        case LinkData(LinkData)
        case Email(Email)
        case Feed(FeedItem)
        case ModifiedThreads([String])
        case ModifiedEmails([Int])
        case NameChanged
        case LabelCreated
        case LabelDeleted
        case LabelEdited
        case Empty
        case News(MailboxData.Feature)
        case UpdateProfilePic
        case CustomerType(Int)
    }
}
