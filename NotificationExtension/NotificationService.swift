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
            let account = SharedDB.getAccountByUsername(username),
            let recipientId = userInfo["recipientId"] as? String,
            let deviceIdString = userInfo["deviceId"] as? String,
            let deviceId = Int32(deviceIdString),
            let messageTypeString = userInfo["previewMessageType"] as? String,
            let messageType = Int(messageTypeString),
            let preview = userInfo["preview"] as? String else {
            contentHandler(request.content)
            return
        }
        
        var decryptedPreview: String? = nil
        tryBlock {
           decryptedPreview = SignalHandler.decryptMessage(preview, messageType: MessageType(rawValue: messageType)!, account: account, recipientId: recipientId, deviceId: deviceId)
        }
        
        guard let decrPreview = decryptedPreview else {
            contentHandler(request.content)
            return
        }
        
        bestAttemptContent.subtitle = bestAttemptContent.body
        bestAttemptContent.body = decrPreview
        bestAttemptContent.categoryIdentifier = "OPEN_THREAD"
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        let defaults = CriptextDefaults()
        if let activeAccount = defaults.activeAccount,
            let contentHandler = contentHandler,
            let bestAttemptContent =  bestAttemptContent {
            bestAttemptContent.categoryIdentifier = "GENERIC_PUSH"
            bestAttemptContent.title = "\(activeAccount)\(Env.domain)"
            bestAttemptContent.body = String.localize("You may have new emails")
            contentHandler(bestAttemptContent)
        }
    }

}
