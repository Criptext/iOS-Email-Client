//
//  NewEmail.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/7/18.
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
    let messageType: MessageType
    let files: [[String: Any]]?
    let fileKey: String?
    let labels: [String]
    
    init(params: [String: Any]){
        threadId = params["threadId"] as! String
        subject = params["subject"] as! String
        messageId = params["messageId"] as! String
        metadataKey = params["metadataKey"] as! Int
        senderDeviceId = params["senderDeviceId"] as? Int32
        messageType = MessageType.init(rawValue: (params["messageType"] as? Int ?? MessageType.none.rawValue))!
        files = params["files"] as? [[String: Any]]
        fileKey = params["fileKey"] as? String
        
        let dateString = params["date"] as! String
        date = NewEmail.convertToDate(dateString: dateString)
        
        from = params["from"] as! String
        to = (params["to"] as? [String]) ?? ServiceContactUtils.prepareContactsStringArray(contactsString: params["to"] as? String)
        cc = (params["cc"] as? [String]) ?? ServiceContactUtils.prepareContactsStringArray(contactsString: params["cc"] as? String)
        bcc = (params["bcc"] as? [String]) ?? ServiceContactUtils.prepareContactsStringArray(contactsString: params["bcc"] as? String)
        labels = (params["labels"] as? [String]) ?? [String]()
    }
    
    static func convertToDate(dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        let timeZone = NSTimeZone(abbreviation: "UTC")
        dateFormatter.timeZone = timeZone as TimeZone?
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateString) ?? Date()
    }
}