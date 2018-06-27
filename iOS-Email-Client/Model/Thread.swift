//
//  Thread.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 6/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class Thread {
    var lastEmail: Email!
    var unread = false
    var counter = 1
    var participants = Set<Contact>()
    var hasAttachments = false
    var participantsString = ""
    var subject = ""
    var date = Date()
    
    var preview : String {
        return lastEmail.preview
    }
    var threadId : String {
        return lastEmail.threadId
    }
    var status : Email.Status {
        return Email.Status(rawValue: lastEmail.delivered) ?? .none
    }
    
    func getFormattedDate() -> String {
        return DateUtils.conversationTime(date)
    }
    
    func getContactsString() -> String{
        var contactsTitle = ""
        for contact in participants {
            guard !contact.displayName.contains("@") else {
                contactsTitle += "\(contact.displayName.split(separator: "@")[0]), "
                continue
            }
            guard participants.count > 1 else {
                contactsTitle += "\(contact.displayName), "
                continue
            }
            contactsTitle += "\(contact.displayName.split(separator: " ")[0]), "
        }
        guard participants.count > 0 else {
            return contactsTitle
        }
        return String(contactsTitle.prefix(contactsTitle.count - 2))
    }
}
