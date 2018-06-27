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
        case none = 0
        case sending = 1
        case sent = 2
        case delivered = 3
        case opened = 4
        case unsent = -1
        case fail = -2
    }
    
    @objc dynamic var id = 0
    @objc dynamic var key = ""
    @objc dynamic var threadId = ""
    @objc dynamic var messageId = ""
    @objc dynamic var unread = true
    @objc dynamic var secure = true
    @objc dynamic var content = ""
    @objc dynamic var preview = ""
    @objc dynamic var subject = ""
    @objc dynamic var delivered = Status.none.rawValue
    @objc dynamic var date = Date()
    @objc dynamic var isMuted = false
    
    let labels = List<Label>()
    let files = List<File>()
    let emailContacts = LinkingObjects(fromType: EmailContact.self, property: "email")
    var isExpanded = false
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
            self.delivered = typeValue.rawValue
        }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["isExpanded"]
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
}

func ==(lhs: Email, rhs: Email) -> Bool {
    return lhs.id == rhs.id
}
