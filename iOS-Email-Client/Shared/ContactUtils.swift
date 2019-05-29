//
//  SharedContactUtils.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ContactUtils {
    class func parseContact(_ contactString: String, account: Account) -> Contact {
        let contactMetadata = self.getStringEmailName(contact: contactString);
        guard let existingContact = SharedDB.getContact(contactMetadata.0) else {
            let newContact = Contact(value: ["displayName": contactMetadata.1, "email": contactMetadata.0])
            SharedDB.store([newContact], account: account)
            return newContact
        }
        let isNewNameFromEmail = contactMetadata.0.starts(with: contactMetadata.1)
        if (!isNewNameFromEmail && contactMetadata.1 != existingContact.displayName) {
            SharedDB.update(contact: existingContact, name: contactMetadata.1)
        }
        return existingContact
    }
    
    class func checkIfFromHasName(_ contact: String) -> Bool {
        let cleanContact = contact.replacingOccurrences(of: "\"", with: "")
        let myContact = NSString(string: cleanContact)
        let pattern = "<(.*?)>"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: cleanContact, options: [], range: NSRange(location: 0, length: myContact.length))
        return matches.last != nil && cleanContact.split(separator: "<").count > 1 ? true : false
    }
    
    class func parseEmailContacts(_ contacts: [String], email: Email, type: ContactType, account: Account){
        contacts.forEach { (contactString) in
            let contact = parseContact(contactString, account: account)
            let emailContact = EmailContact()
            emailContact.contact = contact
            emailContact.email = email
            emailContact.type = type.rawValue
            emailContact.compoundKey = emailContact.buildCompoundKey()
            SharedDB.store([emailContact])
        }
    }
    
    class func parseFromContact(contact: String, account: Account) -> String{
        let from = parseContact(contact, account: account)
        return "\(from.displayName) <\(from.email)>"
    }
    
    class func prepareContactsStringArray(contactsString: String?) -> [String]{
        guard let contactsString = contactsString else {
            return [String]()
        }
        let stringArray = contactsString.split(separator: ",")
        return concatEmailAddresses(stringArray: stringArray, index: 0, result: [String](), remnant: "")
    }
    
    private class func concatEmailAddresses(stringArray: [Substring], index: Int, result: [String], remnant: String) -> [String] {
        guard index < stringArray.count else {
            return result
        }
        let contactString = remnant + stringArray[index]
        if (contactString.contains("@")) {
            return concatEmailAddresses(stringArray: stringArray, index: index+1, result: result + [contactString], remnant: "")
        }
        return concatEmailAddresses(stringArray: stringArray, index: index+1, result: result, remnant: "\(contactString),")
    }
    
    class func getStringEmailName(contact: String, fallback: (String, String)? = nil) -> (String, String) {
        let cleanContact = contact.replacingOccurrences(of: "\"", with: "")
        let myContact = NSString(string: cleanContact)
        let pattern = "<(.*?)>"
        var regex: NSRegularExpression!
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return fallback ?? (contact, contact)
        }
        let matches = regex.matches(in: cleanContact, options: [], range: NSRange(location: 0, length: myContact.length))
        let email = (matches.last != nil ? myContact.substring(with: matches.last!.range(at: 1)) : String(myContact)).lowercased()
        let name = matches.last != nil && cleanContact.split(separator: "<").count > 1 ? cleanContact.prefix(matches.last!.range.location) : email.split(separator: "@")[0]
        return (email, String(name.trimmingCharacters(in: .whitespacesAndNewlines)))
    }
    
    class func getUsernameFromEmailFormat(_ emailFormat: String) -> String? {
        let email = NSString(string: emailFormat)
        let pattern = "(?<=\\<).*(?=@)"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: emailFormat, options: [], range: NSRange(location: 0, length: email.length))
        guard let range = matches.first?.range else {
            return String(emailFormat.split(separator: "@")[0])
        }
        return email.substring(with: range)
    }
    
    class func getDomainFromEmailFormat(_ emailFormat: String) -> String? {
        let email = NSString(string: emailFormat)
        let pattern = "(?<=\\<).*(?=@)"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: emailFormat, options: [], range: NSRange(location: 0, length: email.length))
        guard let range = matches.first?.range else {
            return String(emailFormat.split(separator: "@")[1])
        }
        return email.substring(with: range)
    }
}
