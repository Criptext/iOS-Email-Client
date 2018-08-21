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
        let contactMetadata = self.getStringEmailName(contact: contactString);
        guard let existingContact = DBManager.getContact(contactMetadata.0) else {
            let newContact = Contact(value: ["displayName": contactMetadata.1, "email": contactMetadata.0])
            DBManager.store([newContact])
            return newContact
        }
        let isNewNameFromEmail = contactMetadata.0.starts(with: contactMetadata.1)
        if (!isNewNameFromEmail && contactMetadata.1 != existingContact.displayName) {
            DBManager.update(contact: existingContact, name: contactMetadata.1)
        }
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
    
    class func getStringEmailName(contact: String) -> (String, String) {
        let myContact = NSString(string: contact.replacingOccurrences(of: "\"", with: ""))
        let pattern = "<(.*)>"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: contact, options: [], range: NSRange(location: 0, length: myContact.length))
        let email = (matches.first != nil ? myContact.substring(with: matches.first!.range(at: 1)) : String(myContact)).lowercased()
        let name = matches.first != nil && contact.split(separator: "<").count > 1 ? contact.split(separator: "<")[0] : email.split(separator: "@")[0]
        return (email, String(name.trimmingCharacters(in: .whitespacesAndNewlines)))
    }
}
