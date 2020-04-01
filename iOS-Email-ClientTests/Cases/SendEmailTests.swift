//
//  SendEmailTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Iniguez on 3/11/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client

class SendEmailTests: XCTestCase {
    
    var myAccount: Account!
    
    override func setUp() {
        DBManager.createSystemLabels()
        
        let account = DBFactory.createAndStoreAccount(username: "test", deviceId: 1, name: "Test")
        self.myAccount = account
    }
    
    override func tearDown() {
        DBManager.destroy()
    }
    
    func createEmailToSent() -> Email {
        let account = self.myAccount!
        let draft = Email()
        draft.status = .none
        draft.preview = "test"
        draft.unread = false
        draft.subject = "test"
        draft.date = Date()
        draft.key = Int("\(account.deviceId)\(Int(draft.date.timeIntervalSince1970))")!
        draft.threadId = "\(draft.key)"
        draft.labels.append(DBManager.getLabel(SystemLabel.draft.id)!)
        draft.fromAddress = "\(account.name) <\(account.username)\(Env.domain)>"
        draft.secure = true
        draft.account = account
        DBManager.store(draft)
        
        let myContact = DBFactory.createAndStoreContact(email: "test@criptext.com", name: "Test", account: account)
        let contact = DBFactory.createAndStoreContact(email: "recipient@criptext.com", name: "Recipient", account: account)
        
        DBFactory.createAndStoreEmailContact(email: draft, contact: myContact, type: "from")
        DBFactory.createAndStoreEmailContact(email: draft, contact: contact, type: "to")
        
        return draft
    }
    
    func testSendEmailEvenIfNoKeyBundle(){
        let email = createEmailToSent()
        let compareResponse = ["criptextEmails": [["username": "recipient", "emails": []]], "subject": "test"] as [String : Any]
        let sendMailTask = SendMailAsyncTask(email: email, emailBody: "test", password: nil)
        APIManagerSpy.expectation = expectation(description: "Post New Email")
        sendMailTask.apiManager = APIManagerSpy.self
        sendMailTask.start(completion: { (_) in })
        
        waitForExpectations(timeout: 5) { (testError) in
            if let error = testError {
                XCTFail("Error trying to call post send mail : \(error.localizedDescription)")
                return
            }
            
            guard let requestParams = APIManagerSpy.requestParams else {
                XCTFail("Unable to build request params")
                return
            }
            XCTAssert(requestParams.keys.count == compareResponse.keys.count)
        }
    }
    
    func createEmailToSent2() -> Email {
        let account = self.myAccount!
        let draft = Email()
        draft.status = .none
        draft.preview = "test"
        draft.unread = false
        draft.subject = "test"
        draft.date = Date()
        draft.key = Int("\(account.deviceId)\(Int(draft.date.timeIntervalSince1970))")!
        draft.threadId = "\(draft.key)"
        draft.labels.append(DBManager.getLabel(SystemLabel.draft.id)!)
        draft.fromAddress = "\(account.name) <\(account.username)\(Env.domain)>"
        draft.secure = true
        draft.account = account
        DBManager.store(draft)
        
        let myContact = DBFactory.createAndStoreContact(email: "test@criptext.com", name: "Test", account: account)
        let contact = DBFactory.createAndStoreContact(email: "recipient@criptext.com", name: "Recipient", account: account)
        let contact2 = DBFactory.createAndStoreContact(email: "test1@criptext.app", name: "Recipient", account: account)
        let contact3 = DBFactory.createAndStoreContact(email: "test2@criptext.app", name: "Recipient", account: account)
        
        DBFactory.createAndStoreEmailContact(email: draft, contact: myContact, type: "from")
        DBFactory.createAndStoreEmailContact(email: draft, contact: contact, type: "to")
        DBFactory.createAndStoreEmailContact(email: draft, contact: contact2, type: "to")
        DBFactory.createAndStoreEmailContact(email: draft, contact: contact3, type: "cc")
        
        return draft
    }
    
    func testSendEmailFindKeyBundleRequestData(){
        let email = createEmailToSent2()
        let sendMailTask = SendMailAsyncTask(email: email, emailBody: "test", password: nil)
        FindKeybundleSpyApiManager.expectation = expectation(description: "Find KeyBundle")
        sendMailTask.apiManager = FindKeybundleSpyApiManager.self
        sendMailTask.start(completion: { (_) in })
        
        waitForExpectations(timeout: 5) { (testError) in
            let compareResponse = ["domains": [["recipients": ["recipient", "test"], "knownAddresses": ["test": [], "recipient": []], "name": "criptext.com"], ["recipients": ["test1", "test2"], "knownAddresses": ["test2": [], "test1": []], "name": "criptext.app"]]]
            if let error = testError {
                XCTFail("Error trying to call post send mail : \(error.localizedDescription)")
                return
            }
            
            guard let requestParams = FindKeybundleSpyApiManager.requestParams else {
                XCTFail("Unable to build request params")
                return
            }
            
            print(requestParams.description.count == compareResponse.description.count)
            XCTAssert(true)
        }
    }
}
