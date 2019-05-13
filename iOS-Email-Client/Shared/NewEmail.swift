//
//  NewEmail.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

struct NewEmail {
    let threadId: String
    let subject: String
    let from: String
    let to: [String]
    let cc: [String]
    let bcc: [String]
    let messageId: String
    let date: Date
    let metadataKey: Int
    let senderDeviceId: Int32?
    let inReplyTo: String?
    let messageType: MessageType
    let files: [[String: Any]]?
    let fileKey: String?
    let fileKeys:[String]?
    let labels: [String]
    let isExternal: Bool
    let replyTo: String?
    let boundary: String?
    let guestEncryption: Int
    let recipientId: String?
    
    init(params: [String: Any]) throws {
        guard let paramsFrom = params["from"] as? String,
            let paramsThreadId = params["threadId"] as? String,
            let paramsSubject = params["subject"] as? String,
            let paramsMessageId = params["messageId"] as? String,
            let paramsMetadataKey = params["metadataKey"] as? Int,
            let paramsGuestEncryption = params["guestEncryption"] as? Int else {
            throw CriptextError(message: "Malformed Email")
        }
        
        from = paramsFrom
        threadId = paramsThreadId
        subject = paramsSubject
        messageId = paramsMessageId
        metadataKey = paramsMetadataKey
        guestEncryption = paramsGuestEncryption
        
        senderDeviceId = params["senderDeviceId"] as? Int32
        messageType = MessageType.init(rawValue: (params["messageType"] as? Int ?? MessageType.none.rawValue))!
        files = params["files"] as? [[String: Any]]
        fileKey = params["fileKey"] as? String
        fileKeys = params["fileKeys"] as? [String]
        isExternal = params["external"] as? Bool ?? false
        
        
        let dateString = params["date"] as! String
        date = NewEmail.convertToDate(dateString: dateString)
        
        
        to = (params["to"] as? [String]) ?? ContactUtils.prepareContactsStringArray(contactsString: params["to"] as? String)
        cc = (params["cc"] as? [String]) ?? ContactUtils.prepareContactsStringArray(contactsString: params["cc"] as? String)
        bcc = (params["bcc"] as? [String]) ?? ContactUtils.prepareContactsStringArray(contactsString: params["bcc"] as? String)
        labels = (params["labels"] as? [String]) ?? [String]()
        replyTo = params["replyTo"] as? String
        boundary = params["boundary"] as? String
        inReplyTo = params["inReplyTo"] as? String
        
        if let senderId = params["senderId"] as? String,
            let senderDomain = params["senderDomain"] as? String {
            recipientId = senderDomain == Env.plainDomain ? senderId : "\(senderId)@\(senderDomain)"
        } else {
            recipientId = ContactUtils.getUsernameFromEmailFormat(from)
        }
    }
    
    static func convertToDate(dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        let timeZone = NSTimeZone(abbreviation: "UTC")
        dateFormatter.timeZone = timeZone as TimeZone?
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateString) ?? Date()
    }
}
