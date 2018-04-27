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
    
    @objc dynamic var id = 0
    @objc dynamic var key = ""
    @objc dynamic var threadId = ""
    @objc dynamic var s3Key = ""
    @objc dynamic var unread = true
    @objc dynamic var secure = true
    @objc dynamic var content = ""
    @objc dynamic var preview = ""
    @objc dynamic var subject = ""
    @objc dynamic var delivered = DeliveryStatus.NONE
    @objc dynamic var date : Date?
    let labels = List<Label>()
    let emailContacts = LinkingObjects(fromType: EmailContact.self, property: "email")
    var isExpanded = false
    var counter = 1
    var fromContact : Contact? {
        get {
            let predicate = NSPredicate(format: "type == '\(ContactType.from.rawValue)'")
            let contact = emailContacts.filter(predicate).first?.contact
            return contact
        }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["isExpanded", "counter"]
    }
    
    var isUnsent: Bool{
        return delivered == DeliveryStatus.UNSENT
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
    
    func getContactsString() -> String{
        let contactsTo = getContacts(type: .to)
        let contactsCc = getContacts(type: .cc)
        let contacts = contactsTo + contactsCc
        guard contacts.count > 1 else {
            return contacts.first!.displayName
        }
        var contactsTitle = ""
        for contact in contacts {
            if(contact.displayName.contains("@")){
                contactsTitle += "\(contact.displayName.split(separator: "@")[0]), "
                continue
            }
            contactsTitle += "\(contact.displayName), "
        }
        return String(contactsTitle.prefix(contactsTitle.count - 2))
    }
}

func ==(lhs: Email, rhs: Email) -> Bool {
    return lhs.id == rhs.id
}

struct DeliveryStatus {
    static let NONE = 0
    static let SENT = 1
    static let DELIVERED = 2
    static let OPENED = 3
    static let UNSENT = -1
}
