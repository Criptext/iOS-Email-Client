//
//  EventData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol Dictionarify {
    func asDictionary() throws -> [String: Any]
}

class EventData {
    
    enum Socket {
        case Unhandled
        case Error
        case NewEvent(String, String)
        case PasswordChange
        case Logout
        case RecoveryChanged(String)
        case KeyBundle(Int32)
        case RecoveryVerified
        case LinkData(LinkData, String, String)
        case SyncDeny
        case SyncAccept(AcceptData, String, String)
        case EnterpriseSuspended(String, String)
        case EnterpriseUnSuspended(String, String)
        case LinkDismiss(String, String)
        case SyncDismiss(String, String)
    }
    
    struct Result {
        var emailLabels = [String]()
        var opens = [String]()
        var modifiedThreadIds = [String]()
        var modifiedEmailKeys = [Int]()
        var removed = false
        var suspended = false
        var updateSideMenu = false
        var linkStartData: LinkData? = nil
        var feature: MailboxData.Feature? = nil
        var newCustomerType: Int? = nil
    }
    
    struct NewEmail {
        let threadId: String
        let subject: String
        let from: String
        let replyTo: String
        let fromAddress: String
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
        let boundary: String?
        
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
            date = EventData.convertToDate(dateString: dateString)
            
            from = params["from"] as! String
            replyTo = params["replyTo"] as! String
            fromAddress = params["fromAddress"] as! String
            to = (params["to"] as? [String]) ?? ContactUtils.prepareContactsStringArray(contactsString: params["to"] as? String)
            cc = (params["cc"] as? [String]) ?? ContactUtils.prepareContactsStringArray(contactsString: params["cc"] as? String)
            bcc = (params["bcc"] as? [String]) ?? ContactUtils.prepareContactsStringArray(contactsString: params["bcc"] as? String)
            labels = (params["labels"] as? [String]) ?? [String]()
            boundary = params["boundary"] as? String
        }
    }
    
    struct EmailStatus {
        let emailId: Int
        let from: String
        let fileId: String?
        let date: Date
        let type: Int
        
        init(params: [String: Any]){
            var recipientId = params["from"] as! String
            var domain = Env.plainDomain
            if let fromObject = params["fromDomain"] as? [String: Any] {
                recipientId = fromObject["recipientId"] as! String
                domain = fromObject["domain"] as! String
            }
            emailId = params["metadataKey"] as! Int
            from = "\(recipientId)@\(domain)"
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

extension EventData {
    class Peer {
        
        struct EmailUnreadRaw: Dictionarify {
            let metadataKeys: [Int]
            let unread: Int
            
            init(params: [String: Any]){
                metadataKeys = params["metadataKeys"] as! [Int]
                let unreadValue = params["unread"] as! Int
                unread = unreadValue
            }
            
            init(metadataKeys: [Int], unread: Int){
                self.metadataKeys = metadataKeys
                self.unread = unread
            }
        }
        
        struct EmailUnread: Dictionarify {
            let metadataKeys: [Int]
            let unread: Bool
            
            init(params: [String: Any]){
                metadataKeys = params["metadataKeys"] as! [Int]
                let unreadValue = params["unread"] as! Int
                unread = unreadValue == 0 ? false : true
            }
            
            init(metadataKeys: [Int], unread: Bool){
                self.metadataKeys = metadataKeys
                self.unread = unread
            }
        }
        
        struct ThreadUnread: Dictionarify {
            let threadIds: [String]
            let unread: Bool
            
            init(params: [String: Any]){
                threadIds = params["threadIds"] as! [String]
                let unreadValue = params["unread"] as! Int
                unread = unreadValue == 0 ? false : true
            }
            
            init(threadIds: [String], unread: Bool){
                self.threadIds = threadIds
                self.unread = unread
            }
        }
        
        struct EmailLabels: Dictionarify {
            let metadataKeys: [Int]
            let labelsAdded: [String]
            let labelsRemoved: [String]
            
            init(params: [String: Any]){
                metadataKeys = params["metadataKeys"] as! [Int]
                labelsAdded = params["labelsAdded"] as! [String]
                labelsRemoved = params["labelsRemoved"] as! [String]
            }
            
            init(metadataKeys: [Int], labelsAdded: [String], labelsRemoved: [String]){
                self.metadataKeys = metadataKeys
                self.labelsAdded = labelsAdded
                self.labelsRemoved = labelsRemoved
            }
        }
        
        struct ThreadLabels: Dictionarify {
            let threadIds: [String]
            let labelsAdded: [String]
            let labelsRemoved: [String]
            
            init(params: [String: Any]){
                threadIds = params["threadIds"] as! [String]
                labelsAdded = params["labelsAdded"] as! [String]
                labelsRemoved = params["labelsRemoved"] as! [String]
            }
            
            init(threadIds: [String], labelsAdded: [String], labelsRemoved: [String]){
                self.threadIds = threadIds
                self.labelsAdded = labelsAdded
                self.labelsRemoved = labelsRemoved
            }
        }
        
        struct EmailDeleted: Dictionarify {
            let metadataKeys: [Int]
            
            init(params: [String: Any]){
                metadataKeys = params["metadataKeys"] as! [Int]
            }
            
            init(metadataKeys: [Int]){
                self.metadataKeys = metadataKeys
            }
        }
        
        struct ThreadDeleted: Dictionarify {
            let threadIds: [String]
            
            init(params: [String: Any]){
                threadIds = params["threadIds"] as! [String]
            }
            
            init(threadIds: [String]){
                self.threadIds = threadIds
            }
        }
        
        struct EmailUnsent: Dictionarify {
            let metadataKeys: [Int]
            
            init(params: [String: Any]){
                metadataKeys = params["metadataKeys"] as! [Int]
            }
        }
        
        struct NewLabel: Dictionarify {
            let text: String
            let color: String
            let uuid: String

            init(params: [String: Any]){
                text = params["text"] as! String
                color = params["color"] as! String
                guard let uuid_string = params["uuid"] else{
                    uuid = UUID().uuidString
                    return
                }
                uuid = uuid_string as! String
            }
            
            init(text: String, color: String, uuid: String){
                self.text = text
                self.color = color
                self.uuid = uuid
            }
        }
        
        struct EditLabel: Dictionarify {
            let text: String
            let color: String
            let uuid: String

            init(params: [String: Any]){
                text = params["text"] as! String
                color = params["color"] as? String ?? ""
                uuid = params["uuid"] as! String
            }
            
            init(text: String, color: String, uuid: String){
                self.text = text
                self.color = color
                self.uuid = uuid
            }
        }
        
        struct DeleteLabel: Dictionarify {
            let uuid: String

            init(params: [String: Any]){
                uuid = params["uuid"] as! String
            }
            
            init(uuid: String){
                self.uuid = uuid
            }
        }
        
        struct BlockContent {
            let block: Bool
            
            init(params: [String: Any]){
                let blockInt = params["block"] as! Int
                block = blockInt == 1
            }
        }
        
        struct NameChanged: Dictionarify {
            let name: String
            
            init(params: [String: Any]){
                name = params["name"] as! String
            }
            
            init(name: String){
                self.name = name
            }
        }
        
        struct AddressCreated {
            let id: Int
            let name: String
            let domain: String
            
            init(params: [String: Any]){
                id = params["addressId"] as! Int
                name = params["addressName"] as! String
                domain = params["addressDomain"] as! String
            }
        }
        
        struct AddressStatusUpdate {
            let id: Int
            let active: Bool
            
            init(params: [String: Any]){
                id = params["addressId"] as! Int
                active = params["activate"] as! Bool
            }
        }
        
        struct AddressDeleted {
            let id: Int
            
            init(params: [String: Any]){
                id = params["addressId"] as! Int
            }
        }
        
        struct DomainCreated {
            let name: String
            
            init(params: [String: Any]){
                name = params["customDomain"] as! String
            }
        }
        
        struct DomainDelete {
            let name: String
            
            init(params: [String: Any]){
                name = params["customDomain"] as! String
            }
        }
        
        struct DefaultUpdate {
            let aliasId: Int
            
            init(params: [String: Any]){
                aliasId = params["addressId"] as? Int ?? 0
            }
        }
        
        struct AddressNameUpdate {
            let name: String
            let aliasId: Int
            
            init(params: [String: Any]){
                name = params["fullname"] as! String
                aliasId = params["addressId"] as! Int
            }
        }
        
        struct ContactTrust: Dictionarify {
            let email: String
            let trusted: Bool
            
            init(params: [String: Any]){
                email = params["email"] as! String
                let trustedInt = params["trusted"] as! Int
                trusted = trustedInt == 1
            }
            
            init(email: String, trusted: Bool){
                self.email = email
                self.trusted = trusted
            }
        }
    }
    
    class Acc {
        struct CustomerType {
            let recipientId: String
            let domain: String
            let customerType: Int
            
            init(params: [String: Any]) {
                recipientId = params["recipientId"] as! String
                domain = params["domain"] as! String
                customerType = params["newCustomerType"] as! Int
            }
        }
    }
    
    class Server {
        struct News: Dictionarify {
            let code: String
            let version: String
            let symbol: Int32
            init(params: [String: Any]){
                code = params["code"] as? String ?? ""
                version = params["version"] as? String ?? ""
                symbol = Int32(params["operator"] as? String ?? "1") ?? 1
            }
        }
    }
    
    class Queue {
        struct EmailOpen: Dictionarify {
            let metadataKeys: [Int]
            
            init(metadataKeys: [Int]){
                self.metadataKeys = metadataKeys
            }
        }
    }
}

extension Dictionarify {
    func asDictionary() -> [String: Any] {
        var result = [String: Any]()
        Mirror(reflecting: self).children.forEach { child in
            if let property = child.label {
                result[property] = child.value
            }
        }
        return result
    }
}
