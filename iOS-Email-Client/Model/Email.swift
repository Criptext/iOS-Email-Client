//
//  Email.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/8/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Email: Object {
    @objc dynamic var id = ""
    @objc dynamic var messageId = ""
    @objc dynamic var threadId = ""
    @objc dynamic var historyId:Int64 = 0
    @objc dynamic var subject = ""
    @objc dynamic var threadSubject = ""
    @objc dynamic var from = ""
    @objc dynamic var fromDisplayString = ""
    @objc dynamic var to = ""
    @objc dynamic var toDisplayString = ""
    @objc dynamic var cc = ""
    @objc dynamic var ccDisplayString = ""
    @objc dynamic var date:Date?
    @objc dynamic var dateString = ""
    @objc dynamic var snippet = ""
    @objc dynamic var body = ""
    @objc dynamic var needsSaving = false
    @objc dynamic var needsSending = false
    @objc dynamic var isDisplayed = false
    @objc dynamic var isLoaded = false
    @objc dynamic var realCriptextToken = ""
    @objc dynamic var criptextTokens = [String]()
    @objc dynamic var criptextTokensSerialized = ""
    @objc dynamic var labels = [String]()
    @objc dynamic var labelArraySerialized = ""
    @objc dynamic var nextPageToken:String? = "0"
    var attachments = List<AttachmentGmail>()
    
    func isRead() -> Bool {
        if labels.contains("UNREAD") { return false }
        return true
    }
    
    func isDraft() -> Bool {
        if labels.contains("DRAFT") { return true }
        return false
    }
    
    func usingCriptext() -> Bool {
        if criptextTokensSerialized.characters.count > 0 { return true }
        return false
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["labels", "dateString", "criptextTokens", "isDisplayed", "isLoaded"]
    }
}

func ==(lhs: Email, rhs: Email) -> Bool {
    return lhs.id == rhs.id
}
