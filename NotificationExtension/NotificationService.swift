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
        contentHandler(request.content)
    }
    
    func handleEvents(_ events: [[String: Any]], username: String, for key: Int, completion: @escaping (_ email: Email?) -> Void){
        var focusEvent: [String: Any]? = nil
        for event in events {
            guard let paramsString = event["params"] as? String,
                let params = SharedUtils.convertToDictionary(text: paramsString),
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
        let newEmailHandler = NewEmailHandler(username: username)
        newEmailHandler.command(params: event) { (result) in
            completion(result.email)
        }
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
