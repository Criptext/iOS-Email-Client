//
//  Email.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/8/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

class Email: Object {
    
    enum Status : Int {
        case none = 3
        case sending = 4
        case sent = 5
        case delivered = 6
        case opened = 7
        case unsent = 2
        case fail = 1
    }
    
    struct State {
        var isExpanded: Bool
        var isUnsending: Bool
        var cellHeight: CGFloat
        var trustedOnce: Bool
        
        init() {
            isExpanded = false
            isUnsending = false
            cellHeight = 0.0
            trustedOnce = false
        }
    }
    
    
    @objc dynamic var compoundKey = ""
    @objc dynamic var key = 0 //metadataKey
    @objc dynamic var threadId = ""
    @objc dynamic var messageId = ""
    @objc dynamic var unread = true
    @objc dynamic var secure = true
    @objc dynamic var content = ""
    @objc dynamic var preview = ""
    @objc dynamic var subject = ""
    @objc dynamic var delivered = Status.none.rawValue
    @objc dynamic var date = Date()
    @objc dynamic var unsentDate: Date?
    @objc dynamic var trashDate: Date?
    @objc dynamic var fromAddress = ""
    @objc dynamic var replyTo = ""
    @objc dynamic var boundary = ""
    
    @objc dynamic var account : Account!
    let labels = List<Label>()
    let files = List<File>()
    let emailContacts = LinkingObjects(fromType: EmailContact.self, property: "email")
    var fromContact : Contact {
        get {
            let predicate = NSPredicate(format: "type == '\(ContactType.from.rawValue)'")
            if let contact = emailContacts.filter(predicate).first {
                return contact.contact
            }
            return Contact()
        }
    }
    var status: Status{
        get {
            return Status.init(rawValue: delivered)!
        }
        set(typeValue) {
            if(self.delivered != Status.unsent.rawValue && self.delivered != Status.none.rawValue){
                self.delivered = typeValue.rawValue
            }
        }
    }
    var canTriggerEvent: Bool {
        return status != .fail && status != .sending
    }
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    var isUnsent: Bool{
        return status == .unsent
    }
    
    var isDraft: Bool{
        return labels.contains(where: {$0.id == SystemLabel.draft.id})
    }
    
    var isTrash: Bool{
        return labels.contains(where: {$0.id == SystemLabel.trash.id})
    }
    
    var isSpam: Bool{
        return labels.contains(where: {$0.id == SystemLabel.spam.id})
    }
    
    var isSent: Bool{
        return labels.contains(where: {$0.id == SystemLabel.sent.id})
    }
    
    func buildCompoundKey() {
        self.compoundKey = "\(account.compoundKey):\(key)"
    }
    
    func getContacts(type: ContactType, notEqual email: String = "") -> List<Contact> {
        let contacts = List<Contact>()
        let predicate = NSPredicate(format: "type == '\(type.rawValue)' AND contact.email != '\(email)'")
        let emailContacts = self.emailContacts.filter(predicate)
        emailContacts.forEach { (emailContact) in
            guard let contact = emailContact.contact else {
                return
            }
            contacts.append(contact)
        }
        return contacts
    }
    
    func getContacts(emails: [String]) -> List<Contact> {
        let contacts = List<Contact>()
        let predicate = NSPredicate(format: "contact.email IN %@", emails)
        let emailContacts = self.emailContacts.filter(predicate)
        emailContacts.forEach { (emailContact) in
            guard let contact = emailContact.contact else {
                return
            }
            contacts.append(contact)
        }
        return contacts
    }
        
    func getFormattedDate() -> String {
        return DateUtils.conversationTime(date).replacingOccurrences(of: "Yesterday", with: String.localize("YESTERDAY")).replacingOccurrences(of: "at", with: String.localize("AT"))
    }
    
    func getFullDate() -> String {
        return DateUtils.prettyDate(date).replacingOccurrences(of: "Yesterday", with: String.localize("YESTERDAY")).replacingOccurrences(of: "at", with: String.localize("AT"))
    }
    
    var completeDate: String {
        return DateUtils.date(toCompleteString: self.date).replacingOccurrences(of: "at", with: String.localize("AT"))
    }
    
    func getFiles() -> [File] {
        return Array(files)
    }
    
    func getContacts() -> [Contact] {
        var contacts = [Contact]()
        self.emailContacts.forEach { (emailContact) in
            guard let contact = emailContact.contact else {
                return
            }
            contacts.append(contact)
        }
        return contacts
    }
    
    func getFullContacts() -> String {
        var contacts = String()
        self.emailContacts.forEach { (emailContact) in
            guard let contact = emailContact.contact else {
                return
            }
            
            contacts = contacts.isEmpty ? "\(contact.displayName) <\(contact.email)>" : "\(contacts), \(contact.displayName) <\(contact.email)>"
        }
        return contacts
    }
    
    func getPreview() -> String {
        guard !isUnsent else {
            let stringDate = DateUtils.beautyDate(self.unsentDate ?? Date()).replacingOccurrences(of: "at", with: String.localize("AT"))
            return "\(String.localize("UNSENT")) \(stringDate)"
        }
        return preview
    }
}

extension Email {
    func toDictionary(id: Int, emailBody: String, headers: String) -> [String: Any] {
        let dateString = DateUtils().date(toServerString: date)!
        var object = [
            "id": id,
            "messageId": messageId,
            "threadId": threadId,
            "unread": unread,
            "secure": secure,
            "content": emailBody.isEmpty ? content : emailBody,
            "preview": preview,
            "subject": subject,
            "status": delivered,
            "date": dateString,
            "key": key,
            "fromAddress": fromAddress,
            "replyTo": replyTo,
            "boundary": boundary,
            "headers": headers
        ] as [String: Any]
        if let trashDate = self.trashDate {
            object["trashDate"] = DateUtils().date(toServerString: trashDate)!
        }
        if let unsentDate = self.unsentDate {
            object["unsentDate"] = DateUtils().date(toServerString: unsentDate)!
        }
        return [
            "table": "email",
            "object": object
        ]
    }
    
    func toDictionaryLabels(emailsMap: [Int: Int]) -> [[String: Any]] {
        var existingLabels = Set<Int>()
        return labels.reduce([[String: Any]](), { (result, label) -> [[String: Any]] in
            guard !existingLabels.contains(label.id) else {
                return result
            }
            existingLabels.insert(label.id)
            let dictionary = [
                "table": "email_label",
                "object": [
                    "emailId": emailsMap[self.key],
                    "labelId": label.id,
                ]
                ] as [String : Any]
            return result.appending(dictionary)
        })
    }
}

func ==(lhs: Email, rhs: Email) -> Bool {
    return lhs.key == rhs.key
}
