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
    
    enum Status : Int {
        case none = 3
        case sending = 4
        case sent = 5
        case delivered = 6
        case opened = 7
        case unsent = 2
        case fail = 1
    }
    
    @objc dynamic var id = 0
    @objc dynamic var key = 0
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
    @objc dynamic var isMuted = false
    
    let labels = List<Label>()
    let files = List<File>()
    let emailContacts = LinkingObjects(fromType: EmailContact.self, property: "email")
    var isExpanded = false
    var isUnsending = false
    var isLoaded = false
    var cellHeight : CGFloat = 0.0
    var fromContact : Contact {
        get {
            let predicate = NSPredicate(format: "type == '\(ContactType.from.rawValue)'")
            let contact = emailContacts.filter(predicate).first!.contact!
            return contact
        }
    }
    var status: Status{
        get {
            return Status.init(rawValue: delivered)!
        }
        set(typeValue) {
            if(self.delivered != Status.unsent.rawValue){
                self.delivered = typeValue.rawValue
            }
        }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["isExpanded", "isUnsending", "isLoaded", "cellHeight"]
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
    
    func incrementID() -> Int {
        let realm = try! Realm()
        return (realm.objects(Email.self).max(ofProperty: "id") as Int? ?? 0) + 1
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
    
    func toDictionary() -> [String: Any] {
        let dateString = Formatter.iso8601.string(from: date)
        return ["table": "email",
                "object": [
                    "id": id,
                    "messageId": messageId,
                    "threadId": threadId,
                    "unread": unread,
                    "secure": secure,
                    "content": content,
                    "preview": preview,
                    "subject": subject,
                    "delivered": delivered,
                    "date": dateString,
                    "metadataKey": key,
                    "isMuted": isMuted
            ]
        ]
    }
    
    func getContent() -> String {
        guard !isUnsent else {
            return "<span style=\"color:#eea3a3; font-style: italic;\">Unsent: \(String(DateUtils.beatyDate(self.unsentDate)))</span>"
        }
        return content
    }
    
    func getPreview() -> String {
        guard !isUnsent else {
            return "Unsent: \(String(DateUtils.beatyDate(self.unsentDate)))"
        }
        return preview
    }
}

extension Email: CustomDictionary {
    func toDictionaryLabels() -> [[String: Any]] {
        return labels.map { (label) -> [String: Any] in
            return ["table": "emailLabel",
                    "object": [
                        "emailId": self.id,
                        "labelId": label.id,
                ]
            ]
        }
    }
}

func ==(lhs: Email, rhs: Email) -> Bool {
    return lhs.id == rhs.id
}
