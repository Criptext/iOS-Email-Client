//
//  EventData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class EventData {
    struct NewEmail {
        let threadId: String
        let subject: String
        let from: String
        let to: String
        let cc: String
        let bcc: String
        let messageId: String
        let date: Date
        let metadataKey: Int
        let senderDeviceId: Int32?
        let messageType: MessageType
        let files: [[String: Any]]?
        let fileKey: String?
        
        init(params: [String: Any]){
            threadId = params["threadId"] as! String
            subject = params["subject"] as! String
            from = params["from"] as! String
            to = params["to"] as? String ?? ""
            cc = params["cc"] as? String ?? ""
            bcc = params["bcc"] as? String ?? ""
            messageId = params["messageId"] as! String
            metadataKey = params["metadataKey"] as! Int
            senderDeviceId = params["senderDeviceId"] as? Int32
            messageType = MessageType.init(rawValue: (params["messageType"] as? Int ?? MessageType.none.rawValue))!
            files = params["files"] as? [[String: Any]]
            fileKey = params["fileKey"] as? String
            
            let dateString = params["date"] as! String
            date = EventData.convertToDate(dateString: dateString)
        }
    }
    
    struct EmailStatus {
        let emailId: Int
        let from: String
        let fileId: String?
        let date: Date
        let type: Int
        
        init(params: [String: Any]){
            emailId = params["metadataKey"] as! Int
            from = params["from"] as! String
            fileId = params["file"] as? String
            type = params["type"] as! Int
            
            let dateString = params["date"] as! String
            date = EventData.convertToDate(dateString: dateString)
        }
    }
    
    class func convertToDate(dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        let timeZone = NSTimeZone(abbreviation: "UTC")
        dateFormatter.timeZone = timeZone as TimeZone?
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateString) ?? Date()
    }
}
