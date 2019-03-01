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
        var participants = [Contact]()
        for threadEmail in threadEmails {
            let allContacts = getParticipantContacts(threadEmail: threadEmail, label: label)
            for participant in allContacts {
                guard !participants.contains(where: {$0.email == participant.email}) else {
                    continue
                }
                participants.append(participant)
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
    
    internal func getParticipantContacts(threadEmail: Email, label: Int) -> [Contact] {
        if(label == SystemLabel.sent.id){
            if(threadEmail.labels.contains(where: {$0.id == SystemLabel.sent.id})){
                return Array(threadEmail.getContacts(type: .to)) + Array(threadEmail.getContacts(type: .cc))
            }
        }else{
            if threadEmail.fromAddress.isEmpty {
                return [threadEmail.fromContact]
            } else {
                let contanctInfo = ContactUtils.getStringEmailName(contact: threadEmail.fromAddress)
                if contanctInfo.0.contains(contanctInfo.1) {
                    return [threadEmail.fromContact]
                } else {
                    let tempContact = Contact()
                    tempContact.displayName = contanctInfo.1
                    tempContact.email = contanctInfo.0
                    return [tempContact]
                }
            }
        }
        return []
    }
    
    class func getContactsString(participants: [Contact], replaceWithMe email: String) -> String {
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
