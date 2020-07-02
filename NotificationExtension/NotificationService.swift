//
//  NotificationService.swift
//  NotificationExtension
//
//  Created by Pedro on 11/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import UserNotifications
import RealmSwift
import UIKit

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override init() {
        super.init()
        let fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Env.groupApp)!.appendingPathComponent("default.realm")
        let config = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: Env.databaseVersion)
        Realm.Configuration.defaultConfiguration = config
    }

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        let userInfo = request.content.userInfo
        let defaults = CriptextDefaults()
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        guard !defaults.previewDisable,
            let bestAttemptContent = bestAttemptContent,
            let username = userInfo["account"] as? String,
            let domain = userInfo["domain"] as? String,
            let account = SharedDB.getAccountById(domain == Env.plainDomain ? username : "\(username)@\(domain)"),
            let senderId = userInfo["senderId"] as? String,
            let senderDomain = userInfo["senderDomain"] as? String,
            let deviceIdString = userInfo["deviceId"] as? String,
            let deviceId = Int32(deviceIdString),
            let messageTypeString = userInfo["previewMessageType"] as? String,
            let messageType = Int(messageTypeString),
            let preview = userInfo["preview"] as? String else {
                
            self.bestAttemptContent?.badge = NSNumber(value: SharedDB.getUnreadCounters() + 1)
            contentHandler(self.bestAttemptContent ?? request.content)
            return
        }
        
        let recipientId = senderDomain == Env.plainDomain ? senderId : "\(senderId)@\(senderDomain)"
        var decryptedPreview: String? = nil
        tryBlock {
           decryptedPreview = SignalHandler.decryptMessage(preview, messageType: MessageType(rawValue: messageType)!, account: account, recipientId: recipientId, deviceId: deviceId)
        }
        
        guard let decrPreview = decryptedPreview else {
            contentHandler(request.content)
            return
        }
        
        bestAttemptContent.badge = NSNumber(value: SharedDB.getUnreadCounters() + 1) 
        bestAttemptContent.subtitle = bestAttemptContent.body
        bestAttemptContent.body = condenseWhitespace(phrase: decrPreview)
        bestAttemptContent.categoryIdentifier = "OPEN_THREAD"
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let activeAccount = SharedDB.getActiveAccount(),
            let contentHandler = contentHandler,
            let bestAttemptContent =  bestAttemptContent {
            bestAttemptContent.categoryIdentifier = "GENERIC_PUSH"
            bestAttemptContent.title = activeAccount.email
            bestAttemptContent.body = String.localize("You may have new emails")
            bestAttemptContent.badge = NSNumber(value: SharedDB.getUnreadCounters() + 1)
            contentHandler(bestAttemptContent)
        }
    }
    
    func condenseWhitespace(phrase: String) -> String {
        let components = phrase.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }

}
