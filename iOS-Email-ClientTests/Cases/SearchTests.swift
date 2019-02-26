//
//  SearchTests.swift
//  iOS-Email-ClientTests
//
//  Created by Allisson on 2/26/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import XCTest

@testable import iOS_Email_Client
import Foundation

class SearchTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        DBManager.destroy()
        
        let email1 = createAndStoreEmail(key: 1, preview: "Test Email 1", subject: "Test Email 1", fromAddress: "test1 <test1@criptext.com>")
        let email2 = createAndStoreEmail(key: 2, preview: "Test Email 2", subject: "Test Email 2", fromAddress: "test2 <test2@criptext.com>")
        let email3 = createAndStoreEmail(key: 3, preview: "Test Email 3", subject: "Test Email 3", fromAddress: "test A <test3@criptext.com>")
        let email4 = createAndStoreEmail(key: 4, preview: "Test Email 4", subject: "Test Email 4", fromAddress: "test A <test4@criptext.com>")
        let email5 = createAndStoreEmail(key: 5, preview: "Test Email 5", subject: "Test Email 5", fromAddress: "test3 <test3@criptext.com>")
        
        let contact1 = createAndStoreContact(email: "test1@criptext.com", name: "Test1")
        let contact2 = createAndStoreContact(email: "test2@criptext.com", name: "Test2")
        let contact3 = createAndStoreContact(email: "test3@criptext.com", name: "Test3")
        let contact4 = createAndStoreContact(email: "test4@criptext.com", name: "Test4")
        
        createAndStoreEmailContact(email: email1, contact: contact1, type: "from")
        createAndStoreEmailContact(email: email1, contact: contact2, type: "to")
        createAndStoreEmailContact(email: email1, contact: contact2, type: "cc")
        
        createAndStoreEmailContact(email: email2, contact: contact2, type: "from")
        createAndStoreEmailContact(email: email2, contact: contact1, type: "to")
        
        createAndStoreEmailContact(email: email3, contact: contact3, type: "from")
        createAndStoreEmailContact(email: email3, contact: contact3, type: "cc")
        
        createAndStoreEmailContact(email: email4, contact: contact4, type: "from")
        createAndStoreEmailContact(email: email4, contact: contact2, type: "to")
        
        createAndStoreEmailContact(email: email5, contact: contact3, type: "from")
        createAndStoreEmailContact(email: email5, contact: contact1, type: "to")
    }
    
    @discardableResult func createAndStoreEmail(key: Int, preview: String, subject: String, fromAddress: String) -> Email {
        let newEmail = Email()
        newEmail.key = key
        newEmail.threadId = key.description
        newEmail.preview = preview
        newEmail.subject = subject
        newEmail.fromAddress = fromAddress
        DBManager.store(newEmail)
        
        return newEmail
    }
    
    @discardableResult func createAndStoreContact(email: String, name: String) -> Contact {
        let newContact = Contact()
        newContact.email = email
        newContact.displayName = name
        DBManager.store([newContact])
        
        return newContact
    }
    
    func createAndStoreEmailContact(email: Email, contact: Contact, type: String) {
        let emailContact = EmailContact()
        emailContact.contact = contact
        emailContact.email = email
        emailContact.type = type
        
        DBManager.store([emailContact])
    }
    
    func testEncryptedAndDecryptMessageSuccessfully() {
        let searchText = "test A"
        let threadResults = DBManager.getThreads(since: Date(), searchParam: searchText)
        
        XCTAssert(threadResults.count == 2)
    }
}
