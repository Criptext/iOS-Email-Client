//
//  Thread.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 6/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Thread {
    var unread = false
    var counter = 1
    var hasAttachments = false
    var subject = ""
    var threadId = ""
    var date = Date()
    var preview = ""
    var status : Email.Status = .none
    var isStarred = false
    var canTriggerEvent = false
    var contactsString = ""
    var isUnsent = false
    var lastEmailKey = 0
    var lastContact = ("", "")
    
    func getFormattedDate() -> String {
        return DateUtils.conversationTime(date).replacingOccurrences(of: "Yesterday", with: String.localize("YESTERDAY"))
    }
    
    func fromLastEmail(lastEmail: Email, threadEmails: Results<Email>, label: Int) {
        self.preview = lastEmail.getPreview()
        self.status = Email.Status(rawValue: lastEmail.delivered) ?? .none
        self.isStarred = lastEmail.labels.contains(where: {$0.id == SystemLabel.starred.id})
        self.canTriggerEvent = counter > 1 || (lastEmail.status != .fail && lastEmail.status != .sending)
        self.date = lastEmail.date
        self.lastEmailKey = lastEmail.key
        self.isUnsent = lastEmail.isUnsent
        self.threadId = lastEmail.threadId
        self.unread = threadEmails.contains(where: {$0.unread})
        self.counter = threadEmails.count
        self.subject = threadEmails.first!.subject
        var participants = Set<Contact>()
        for threadEmail in threadEmails {
            if(label == SystemLabel.sent.id){
                if(threadEmail.labels.contains(where: {$0.id == SystemLabel.sent.id})){
                    participants.formUnion(threadEmail.getContacts(type: .to))
                    participants.formUnion(threadEmail.getContacts(type: .cc))
                }
            }else{
                participants.formUnion(threadEmail.getContacts(type: .from))
            }
            if(!self.hasAttachments && threadEmail.files.count > 0){
                self.hasAttachments = true
            }
        }
        self.contactsString = Thread.getContactsString(participants: participants, replaceWithMe: "pedro@criptext.com")
        if let contact = participants.first {
            self.lastContact = (contact.email, contact.displayName)
        }
    }
    
    
    class func getContactsString(participants: Set<Contact>, replaceWithMe email: String) -> String {
        var contactsTitle = ""
        for contact in participants {
            let contactName = contact.email == email ? String.localize("ME") : contact.displayName
            guard !contact.displayName.contains("@") else {
                contactsTitle += "\(contactName.split(separator: "@").first!), "
                continue
            }
            guard participants.count > 1 else {
                contactsTitle += "\(contactName), "
                continue
            }
            contactsTitle += "\(contactName.split(separator: " ").first ?? Substring(contactName)), "
        }
        guard participants.count > 0 else {
            return contactsTitle
        }
        return String(contactsTitle.prefix(contactsTitle.count - 2))
    }
}
