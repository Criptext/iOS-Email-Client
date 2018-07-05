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
    
    var isStarred : Bool {
        return lastEmail.labels.contains(where: {$0.id == SystemLabel.starred.id})
    }
    
    func getFormattedDate() -> String {
        return DateUtils.conversationTime(date)
    }
    
    func getContactsString(replaceWithMe email: String) -> String{
        var contactsTitle = ""
        for contact in participants {
            let contactName = contact.email == email ? "Me" : contact.displayName
            guard !contact.displayName.contains("@") else {
                contactsTitle += "\(contactName), "
                continue
            }
            guard participants.count > 1 else {
                contactsTitle += "\(contactName), "
                continue
            }
            contactsTitle += "\(contactName), "
        }
        guard participants.count > 0 else {
            return contactsTitle
        }
        return String(contactsTitle.prefix(contactsTitle.count - 2))
    }
}
