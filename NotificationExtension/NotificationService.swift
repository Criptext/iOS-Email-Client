//
//  NotificationService.swift
//  NotificationExtension
//
//  Created by Allisson on 11/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import UserNotifications
import RealmSwift

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override init() {
        super.init()
        
        let fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.criptext.team")!.appendingPathComponent("default.realm")
        let config = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: Env.databaseVersion)
        Realm.Configuration.defaultConfiguration = config
    }

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        let groupDefaults = UserDefaults.init(suiteName: Env.groupApp)!
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        guard let bestAttemptContent = bestAttemptContent,
            let username = groupDefaults.string(forKey: "activeAccount"),
            let account = SharedDB.getAccountByUsername(username) else {
                contentHandler(request.content)
                return
        }
        SharedAPI.getEvents(token: account.jwt) { (responseData) in
            let userInfo = request.content.userInfo
            guard case let .SuccessArray(events) = responseData,
                let keyString = userInfo["metadataKey"] as? String,
                let key = Int(keyString) else {
                contentHandler(request.content)
                return
            }
            self.handleEvents(events, username: username, for: key) { responseEmail in
                guard let email = responseEmail else {
                    contentHandler(request.content)
                    return
                }
                
                
                if groupDefaults.bool(forKey: "previewDisable") {
                    bestAttemptContent.title = email.fromContact.displayName
                    bestAttemptContent.body = email.subject
                } else {
                    bestAttemptContent.title = email.fromContact.displayName
                    bestAttemptContent.subtitle = email.subject
                    bestAttemptContent.body = email.preview
                }
                contentHandler(bestAttemptContent)
            }
        }
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
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
