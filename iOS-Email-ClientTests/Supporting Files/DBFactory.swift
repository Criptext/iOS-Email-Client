//
//  DBFactory.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Iniguez on 2/27/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
@testable import iOS_Email_Client

class DBFactory {
    
    @discardableResult class func createAndStoreAccount(username: String, deviceId: Int, name: String) -> Account {
        let newAccount = Account()
        newAccount.name = name
        newAccount.username = username
        newAccount.deviceId = deviceId
        newAccount.buildCompoundKey()
        DBManager.store(newAccount)
        
        return newAccount
    }
    
    @discardableResult class func createAndStoreEmail(key: Int, preview: String, subject: String, fromAddress: String, threadId: String? = nil, account: Account) -> Email {
        let newEmail = Email()
        newEmail.key = key
        newEmail.threadId = threadId ?? key.description
        newEmail.preview = preview
        newEmail.subject = subject
        newEmail.fromAddress = fromAddress
        newEmail.account = account
        newEmail.buildCompoundKey()
        DBManager.store(newEmail)
        
        return newEmail
    }
    
    @discardableResult class func createAndStoreContact(email: String, name: String, account: Account) -> Contact {
        let newContact = Contact()
        newContact.email = email
        newContact.displayName = name
        DBManager.store([newContact], account: account)
        
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
