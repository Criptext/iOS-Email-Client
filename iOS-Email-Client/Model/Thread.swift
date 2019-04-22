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
    var contactsString: NSAttributedString?
    var isUnsent = false
    var lastEmailKey = 0
    var lastContact = ("", "")
    var participants = [DisplayContact]()
    
    internal struct DisplayContact {
        var name: String
        var isDraft: Bool
        var isUnread: Bool
    }
    
    func getFormattedDate() -> String {
        return DateUtils.conversationTime(date).replacingOccurrences(of: "Yesterday", with: String.localize("YESTERDAY"))
    }
    
    func fromLastEmail(lastEmail: Email, threadEmails: Results<Email>, label: Int, myEmail: String) {
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
        var emailParticipants = Set<String>()
        var firstParticipant: DisplayContact?
        for threadEmail in threadEmails.reversed() {
            let allContacts = getParticipantContacts(threadEmail: threadEmail, label: label)
            for participant in allContacts {
                guard !emailParticipants.contains(participant.email) else {
                    continue
                }
                if firstParticipant == nil {
                    let firstName = Thread.getContactString(contact: participant, replaceWithMe: myEmail)
                    firstParticipant = DisplayContact(name: firstName, isDraft: threadEmail.isDraft, isUnread: threadEmail.unread)
                }
                let displayName = Thread.getContactString(contact: participant, multiple: threadEmails.count > 1 || allContacts.count > 1, isDraft: threadEmail.isDraft, replaceWithMe: myEmail)
                emailParticipants.insert(participant.email)
                self.participants.append(DisplayContact(name: displayName, isDraft: threadEmail.isDraft, isUnread: threadEmail.unread))
            }
            if(!self.hasAttachments && threadEmail.files.count > 0){
                self.hasAttachments = true
            }
        }
        if emailParticipants.count < 2,
            let participant = firstParticipant {
            self.participants.removeAll()
            self.participants.append(participant)
        }
        if let contact = threadEmails.last?.fromContact {
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
    
    class func getContactString(contact: Contact, multiple: Bool = false, isDraft: Bool = false, replaceWithMe email: String) -> String {
        guard !isDraft else {
            return String.localize("SINGLE_DRAFT")
        }
        guard contact.email != email else {
            return String.localize("ME")
        }
        guard multiple else {
            return contact.displayName
        }
        return String(contact.displayName.split(separator: " ").first ?? Substring(contact.displayName))
    }
    
    func buildContactString(theme: Theme, fontSize: CGFloat) -> NSAttributedString {
        if let myAttrString = self.contactsString {
            return myAttrString
        }
        let attrString = NSMutableAttributedString(string: "")
        for (index, participant) in self.participants.reversed().enumerated() {
            let textColor = participant.isDraft ? theme.alert : (participant.isUnread ? theme.markedText : theme.mainText)
            let textFont = participant.isUnread ? Font.bold.size(fontSize)! : Font.regular.size(fontSize)!
            let attrs = [.foregroundColor: textColor, .font: textFont] as [NSAttributedStringKey: Any]
            if index == 0 {
                attrString.append(NSAttributedString(string: participant.name, attributes: attrs))
            } else {
                attrString.append(NSAttributedString(string: ", ", attributes: [.foregroundColor: theme.mainText, .font: Font.regular.size(fontSize)!]))
                attrString.append(NSAttributedString(string: participant.name, attributes: attrs))
            }
        }
        self.contactsString = attrString
        return attrString
    }
}
