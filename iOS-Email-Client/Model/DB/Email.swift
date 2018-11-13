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
        
        init() {
            isExpanded = false
            isUnsending = false
            cellHeight = 0.0
        }
    }
    
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
    @objc dynamic var isMuted = false
    
    let labels = List<Label>()
    let files = List<File>()
    let emailContacts = LinkingObjects(fromType: EmailContact.self, property: "email")
    var fromContact : Contact {
        get {
            let predicate = NSPredicate(format: "type == '\(ContactType.from.rawValue)'")
            return emailContacts.filter(predicate).first!.contact
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
        return "key"
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
        
    func getFormattedDate() -> String {
        return DateUtils.conversationTime(date)
    }
    
    func getFullDate() -> String {
        return DateUtils.prettyDate(date)
    }
    
    var completeDate: String {
        return DateUtils.date(toCompleteString: self.date)
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
    
    func getContent() -> String {
        guard !isUnsent else {
            return "<span style=\"color:#eea3a3; font-style: italic;\">Unsent \(String(DateUtils.beautyDate(self.unsentDate ?? Date())))</span>"
        }
        return content
    }
    
    func getPreview() -> String {
        guard !isUnsent else {
            return "Unsent \(String(DateUtils.beautyDate(self.unsentDate ?? Date())))"
        }
        return preview
    }
}

extension Email {
    func toDictionary(id: Int) -> [String: Any] {
        let dateString = DateUtils().date(toServerString: date)!
        var object = [
            "id": id,
            "messageId": messageId,
            "threadId": threadId,
            "unread": unread,
            "secure": secure,
            "content": content,
            "preview": preview,
            "subject": subject,
            "status": delivered,
            "date": dateString,
            "key": key,
            "isMuted": isMuted
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
        return labels.map { (label) -> [String: Any] in
            return [
                "table": "email_label",
                "object": [
                    "emailId": emailsMap[self.key],
                    "labelId": label.id,
                ]
            ]
        }
    }
}

func ==(lhs: Email, rhs: Email) -> Bool {
    return lhs.key == rhs.key
}
