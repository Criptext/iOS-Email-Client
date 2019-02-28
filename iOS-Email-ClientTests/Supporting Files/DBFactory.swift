//
//  DBFactory.swift
//  iOS-Email-ClientTests
//
//  Created by Allisson on 2/27/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
@testable import iOS_Email_Client

class DBFactory {
    @discardableResult class func createAndStoreEmail(key: Int, preview: String, subject: String, fromAddress: String, threadId: String? = nil) -> Email {
        let newEmail = Email()
        newEmail.key = key
        newEmail.threadId = threadId ?? key.description
        newEmail.preview = preview
        newEmail.subject = subject
        newEmail.fromAddress = fromAddress
        DBManager.store(newEmail)
        
        return newEmail
    }
    
    @discardableResult class func createAndStoreContact(email: String, name: String) -> Contact {
        let newContact = Contact()
        newContact.email = email
        newContact.displayName = name
        DBManager.store([newContact])
        
        return newContact
    }
    
    class func createAndStoreEmailContact(email: Email, contact: Contact, type: String) {
        let emailContact = EmailContact()
        emailContact.contact = contact
        emailContact.email = email
        emailContact.type = type
        emailContact.compoundKey = emailContact.buildCompoundKey()
        DBManager.store([emailContact])
    }
}
