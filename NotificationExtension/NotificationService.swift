//
//  NotificationService.swift
//  NotificationExtension
//
//  Created by Allisson on 11/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import UserNotifications
import SwiftSoup

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    let database = Database()
    let apiRequest = APIRequest()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        guard let bestAttemptContent = bestAttemptContent,
            let account = database.getFirstAccount() else {
                contentHandler(request.content)
                return
        }
        apiRequest.getEvents(token: account.jwt) { (events) in
            let userInfo = request.content.userInfo
            guard let myEvents = events,
                let keyString = userInfo["metadataKey"] as? String,
                let key = Int(keyString) else {
                contentHandler(request.content)
                return
            }
            self.handleEvents(myEvents, for: key) { responseEmail in
                guard let email = responseEmail else {
                    contentHandler(request.content)
                    return
                }
                bestAttemptContent.title = email.fromContact.displayName
                bestAttemptContent.subtitle = email.subject
                bestAttemptContent.body = email.preview
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    func handleEvents(_ events: [[String: Any]], for key: Int, completion: @escaping (_ email: Email?) -> Void){
        var focusEvent: [String: Any]? = nil
        for event in events {
            guard let paramsString = event["params"] as? String,
                let params = convertToDictionary(text: paramsString),
                let emailKey = params["metadataKey"] as? Int,
                emailKey == key else {
                continue
            }
            focusEvent = params
            break
        }
        guard let event = focusEvent else {
            completion(nil)
            return
        }
        handleNewEmailCommand(params: event, completion: completion)
    }
    
    func handleNewEmailCommand(params: [String: Any], completion: @escaping (_ email: Email?) -> Void){
        guard let myAccount = database.getFirstAccount() else {
            completion(nil)
            return
        }
        let event = NewEmail.init(params: params)
        
        let email = Email()
        email.threadId = event.threadId
        email.subject = event.subject
        email.key = event.metadataKey
        email.messageId = event.messageId
        email.date = event.date
        email.unread = true
        
        apiRequest.getEmailBody(metadataKey: email.key, token: myAccount.jwt) { (bodyResponse) in
            guard let myAccount = self.database.getFirstAccount(),
                let body = bodyResponse,
                let username = ServiceContactUtils.getUsernameFromEmailFormat(event.from),
                let content = self.handleBodyByMessageType(event.messageType, body: body, account: myAccount, recipientId: username, senderDeviceId: event.senderDeviceId) else {
                completion(nil)
                return
            }
            
            let contentPreview = self.getContentPreview(content: content)
            email.content = contentPreview.1
            email.preview = contentPreview.0
            
            guard self.database.store(email) else {
                completion(nil)
                return
            }
            
            ServiceContactUtils.parseEmailContacts([event.from], database: self.database, email: email, type: .from)
            ServiceContactUtils.parseEmailContacts(event.to, database: self.database, email: email, type: .to)
            ServiceContactUtils.parseEmailContacts(event.cc, database: self.database, email: email, type: .cc)
            ServiceContactUtils.parseEmailContacts(event.bcc, database: self.database, email: email, type: .bcc)
            
            completion(email)
        }
    }
    
    func handleBodyByMessageType(_ messageType: MessageType, body: String, account: Account, recipientId: String, senderDeviceId: Int32?) -> String? {
        guard messageType != .none,
            let deviceId = senderDeviceId else {
                return body
        }
        return SignalHandler.decryptMessage(body, messageType: messageType, account: account, recipientId: recipientId, deviceId: deviceId)
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
    
    func convertToDictionary(text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else {
            return nil
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
