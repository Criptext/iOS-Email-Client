//
//  ThreadTests.swift
//  iOS-Email-ClientTests
//
//  Created by Allisson on 2/27/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client
@testable import Firebase

class ThreadTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        DBManager.destroy()
        let email1 = DBFactory.createAndStoreEmail(key: 1, preview: "test 1", subject: "testing 1", fromAddress: "test 1 <test1@criptext>", threadId: "1")
        let email2 = DBFactory.createAndStoreEmail(key: 2, preview: "test 2", subject: "testing 2", fromAddress: "testing <test2@criptext>", threadId: "1")
        let email3 = DBFactory.createAndStoreEmail(key: 3, preview: "test 3", subject: "testing 3", fromAddress: "testope <test3@criptext>", threadId: "1")
        
        let contact1 = DBFactory.createAndStoreContact(email: "test@criptext", name: "Test1")
        let contact2 = DBFactory.createAndStoreContact(email: "test2@criptext", name: "Test2")
        let contact3 = DBFactory.createAndStoreContact(email: "test3@criptext", name: "Test3")
        let contact4 = DBFactory.createAndStoreContact(email: "test4@criptext", name: "Test4")
        
        DBFactory.createAndStoreEmailContact(email: email1, contact: contact1, type: "from")
        DBFactory.createAndStoreEmailContact(email: email1, contact: contact2, type: "to")
        
        DBFactory.createAndStoreEmailContact(email: email2, contact: contact2, type: "from")
        DBFactory.createAndStoreEmailContact(email: email2, contact: contact1, type: "to")
        DBFactory.createAndStoreEmailContact(email: email2, contact: contact3, type: "cc")
        
        DBFactory.createAndStoreEmailContact(email: email3, contact: contact3, type: "from")
        DBFactory.createAndStoreEmailContact(email: email3, contact: contact4, type: "to")
    }
    
    func testBuildThreadParticipants() {
        DBManager.refresh()
        guard let thread = DBManager.getThread(threadId: "1", label: SystemLabel.all.id) else {
            XCTFail("no thread")
            return
        }
        XCTAssert(thread.counter == 3, "wrong thread")
        XCTAssert(thread.contactsString == "test, testing, testope", "wrong participants - got \(thread.contactsString)")
    }
}
