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
            if let existingContact = DBManager.getContact(cString) {
                return existingContact
            }
            return Contact(value: ["displayName": cString.split(separator: "@")[0], "email": cString])
        }
        let splittedContact = contactString.split(separator: "<")
        guard splittedContact.count > 1 else {
            if let existingContact = DBManager.getContact(contactString) {
                return existingContact
            }
            return Contact(value: ["displayName": contactString.split(separator: "@")[0], "email": contactString])
        }
        let contactName = splittedContact[0].prefix((splittedContact[0].count - 1))
        let email = splittedContact[1].prefix((splittedContact[1].count - 1)).replacingOccurrences(of: ">", with: "")
        if let existingContact = DBManager.getContact(email) {
            DBManager.update(contact: existingContact, name: String(contactName))
            return existingContact
        }
        let newContact = Contact(value: ["displayName": contactName, "email": email])
        DBManager.store([newContact])
        return newContact
    }
    
    class func parseEmailContacts(_ contactsString: String, email: Email, type: ContactType){
        let contacts = contactsString.split(separator: ",")
        contacts.forEach { (contactString) in
            let contact = parseContact(String(contactString))
            let emailContact = EmailContact()
            emailContact.contact = contact
            emailContact.email = email
            emailContact.type = type.rawValue
            DBManager.store([emailContact])
        }
    }
}
