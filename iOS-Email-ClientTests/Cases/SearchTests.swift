//
//  SearchTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Iniguez on 2/26/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import XCTest

@testable import iOS_Email_Client
import Foundation

class SearchTests: XCTestCase {
    
    var account: Account!
    
    override func setUp() {
        super.setUp()
        DBManager.destroy()
        
        self.account = DBFactory.createAndStoreAccount(username: "test", deviceId: 1, name: "Test")
        
        let email1 = DBFactory.createAndStoreEmail(key: 1, preview: "Test Email 1", subject: "Test Email 1", fromAddress: "test1 <test1@criptext.com>", account: account)
        let email2 = DBFactory.createAndStoreEmail(key: 2, preview: "Test Email 2", subject: "Test Email 2", fromAddress: "test2 <test2@criptext.com>", account: account)
        let email3 = DBFactory.createAndStoreEmail(key: 3, preview: "Test Email 3", subject: "Test Email 3", fromAddress: "test A <test3@criptext.com>", account: account)
        let email4 = DBFactory.createAndStoreEmail(key: 4, preview: "Test Email 4", subject: "Test Email 4", fromAddress: "test A <test4@criptext.com>", account: account)
        let email5 = DBFactory.createAndStoreEmail(key: 5, preview: "Test Email 5", subject: "Test Email 5", fromAddress: "test3 <test3@criptext.com>", account: account)
        
        let contact1 = DBFactory.createAndStoreContact(email: "test1@criptext.com", name: "Test1", account: account)
        let contact2 = DBFactory.createAndStoreContact(email: "test2@criptext.com", name: "Test2", account: account)
        let contact3 = DBFactory.createAndStoreContact(email: "test3@criptext.com", name: "Test3", account: account)
        let contact4 = DBFactory.createAndStoreContact(email: "test4@criptext.com", name: "Test4", account: account)
        
        DBFactory.createAndStoreEmailContact(email: email1, contact: contact1, type: "from")
        DBFactory.createAndStoreEmailContact(email: email1, contact: contact2, type: "to")
        DBFactory.createAndStoreEmailContact(email: email1, contact: contact2, type: "cc")
        
        DBFactory.createAndStoreEmailContact(email: email2, contact: contact2, type: "from")
        DBFactory.createAndStoreEmailContact(email: email2, contact: contact1, type: "to")
        
        DBFactory.createAndStoreEmailContact(email: email3, contact: contact3, type: "from")
        DBFactory.createAndStoreEmailContact(email: email3, contact: contact3, type: "cc")
        
        DBFactory.createAndStoreEmailContact(email: email4, contact: contact4, type: "from")
        DBFactory.createAndStoreEmailContact(email: email4, contact: contact2, type: "to")
        
        DBFactory.createAndStoreEmailContact(email: email5, contact: contact3, type: "from")
        DBFactory.createAndStoreEmailContact(email: email5, contact: contact1, type: "to")
    }
    
    func testEncryptedAndDecryptMessageSuccessfully() {
        let searchText = "test A"
        let threadResults = DBManager.getThreads(since: Date(), searchParam: searchText, account: self.account)
        
        XCTAssert(threadResults.count == 2)
    }
}
