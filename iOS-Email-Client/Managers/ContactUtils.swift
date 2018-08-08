//
//  ContactManager.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 5/19/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import Contacts

class ContactUtils {
    static let store = CNContactStore()
        
    private class func parseContact(_ contactString: String) -> Contact {
        guard !contactString.starts(with: "<") else {
            let cString = contactString.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
            guard let existingContact = DBManager.getContact(cString) else {
                return Contact(value: ["displayName": cString.split(separator: "@")[0], "email": cString])
            }
            return existingContact
        }
        let splittedContact = contactString.split(separator: "<")
        guard splittedContact.count > 1 else {
            guard let existingContact = DBManager.getContact(contactString) else {
                return Contact(value: ["displayName": contactString.split(separator: "@")[0], "email": contactString])
            }
            return existingContact
        }
        let contactName = splittedContact[0].prefix((splittedContact[0].count - 1))
        let email = splittedContact[1].prefix((splittedContact[1].count - 1)).replacingOccurrences(of: ">", with: "")
        guard let existingContact = DBManager.getContact(email) else {
            let newContact = Contact(value: ["displayName": contactName, "email": email])
            DBManager.store([newContact])
            return newContact
        }
        DBManager.update(contact: existingContact, name: String(contactName))
        return existingContact
    }
    
    class func parseEmailContacts(_ contactsString: String, email: Email, type: ContactType){
        let contacts = contactsString.split(separator: ",")
        contacts.forEach { (contactString) in
            let contact = parseContact(String(contactString.replacingOccurrences(of: "\"", with: "")))
            let emailContact = EmailContact()
            emailContact.contact = contact
            emailContact.email = email
            emailContact.type = type.rawValue
            DBManager.store([emailContact])
        }
    }
}
