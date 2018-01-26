//
//  Attachment.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/15/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum ExpirationType: Int {
    case regular = 1
    case open = 2
    case send = 3
}

//class AttachmentCriptext: Object {
//    dynamic var userId = ""
//    dynamic var fileName = ""
//    dynamic var fileSize = ""
//    dynamic var fileToken = ""
//    dynamic var fileType = ""
//    dynamic var password = ""
//    dynamic var readOnly = ""
//    dynamic var remoteUrl = ""
//    dynamic var timestamp = ""
//    dynamic var token = ""
//    dynamic var openArraySerialized = ""
//    dynamic var openArray = [String]()
//    dynamic var downloadArraySerialized = ""
//    dynamic var downloadArray = [String]()
//    
//    override static func primaryKey() -> String? {
//        return "fileToken"
//    }
//    
//    override static func ignoredProperties() -> [String] {
//        return ["openArray", "downloadArray"]
//    }
//}

//attachments -> Array[]
//exists -> 1 else unsent
//isnew -> 1 delivered else open
//openlocation -> Array["device:location"]
//secondsSet -> seconds originally set to expire
//subject
//to
//token
//tipo -> 2 expiration on open, 3 expiration on send
class AttachmentGmail: Object, Attachment {

    dynamic var currentPassword = ""
    dynamic var attachmentId = ""
    dynamic var contentId = ""
    dynamic var fileName = ""
    dynamic var filePath = ""
    dynamic var fileToken = ""
    dynamic var mimeType = ""
    dynamic var size = 0
    dynamic var isReadOnly = false
    dynamic var isEncrypted = false
    dynamic var isUploaded = false
    
    var fileURL: URL? {
        if attachmentId.isEmpty {
            return URL(fileURLWithPath: self.filePath)
        }
        
        let substring = attachmentId.substring(to: attachmentId.index(attachmentId.startIndex, offsetBy: 10))
        
        return URL(fileURLWithPath: "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)/\(substring)\(fileName)")
    }
    
    var filesize:String {
        return ByteCountFormatter.string(fromByteCount: Int64(self.size), countStyle: .file)
    }
    
    override static func primaryKey() -> String? {
        return "attachmentId"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["isReadOnly", "isEncrypted", "filesize", "fileURL", "currentPassword"]
    }
}

protocol Attachment {

    var fileName:String { get set }
    var size:Int { get set }
    var isEncrypted:Bool { get set }
    var isReadOnly:Bool { get set }
    var mimeType:String { get set }
    var fileToken:String { get set }
    var fileURL:URL? { get }
    var filePath:String { get set }
    var filesize:String { get }
    var currentPassword:String { get set }
    var isUploaded:Bool { get set }
}

func ==(lhs: Attachment, rhs: Attachment) -> Bool {
    return lhs.fileName == rhs.fileName
}

class AttachmentCriptext: Object, Attachment {
    dynamic var filePath:String = ""
    //sent
    dynamic var id = "" // fileToken
    dynamic var fileName = ""
    dynamic var fileToken = ""
    dynamic var size = 0
    dynamic var isEncrypted = true
    dynamic var isReadOnly = false
    dynamic var isUploaded = false
    dynamic var currentPassword = ""
    dynamic var mimeType = ""
    
    //Criptext
    dynamic var userId = ""
    dynamic var emailToken = ""
    dynamic var fileType = ""
    dynamic var remoteUrl = ""
    dynamic var timestamp = ""
    dynamic var openArraySerialized = ""
    dynamic var openArray = [String]()
    dynamic var downloadArraySerialized = ""
    dynamic var downloadArray = [String]()

    //Attachment Criptext
    override static func primaryKey() -> String? {
        return "fileToken"
    }
    
    //////////////
    
    var filesize:String {
        return ByteCountFormatter.string(fromByteCount: Int64(self.size), countStyle: .file)
    }
    
    var fileURL: URL? {
        return URL(fileURLWithPath: self.filePath)
    }
    
    override static func ignoredProperties() -> [String] {
        return ["openArray", "downloadArray", "filesize", "fileURL"]
    }
}
