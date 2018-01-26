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
    dynamic var id = ""
    dynamic var messageId = ""
    dynamic var threadId = ""
    dynamic var historyId:Int64 = 0
    dynamic var subject = ""
    dynamic var threadSubject = ""
    dynamic var from = ""
    dynamic var fromDisplayString = ""
    dynamic var to = ""
    dynamic var toDisplayString = ""
    dynamic var cc = ""
    dynamic var ccDisplayString = ""
    dynamic var date:Date?
    dynamic var dateString = ""
    dynamic var snippet = ""
    dynamic var body = ""
    dynamic var needsSaving = false
    dynamic var needsSending = false
    dynamic var isDisplayed = false
    dynamic var isLoaded = false
    dynamic var realCriptextToken = ""
    dynamic var criptextTokens = [String]()
    dynamic var criptextTokensSerialized = ""
    dynamic var labels = [String]()
    dynamic var labelArraySerialized = ""
    dynamic var nextPageToken:String? = "0"
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
