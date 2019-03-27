//
//  SendEmailTests.swift
//  iOS-Email-ClientTests
//
//  Created by Allisson on 3/11/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client

class SendEmailTests: XCTestCase {
    
    var myAccount: Account!
    var email: Email!
    
    override func setUp() {
        DBManager.createSystemLabels()
        
        let account = DBFactory.createAndStoreAccount(username: "test", deviceId: 1, name: "Test")
        self.myAccount = account
        
        let draft = Email()
        draft.status = .none
        draft.preview = "test"
        draft.unread = false
        draft.subject = "test"
        draft.date = Date()
        draft.key = Int("\(account.deviceId)\(Int(draft.date.timeIntervalSince1970))")!
        draft.threadId = "\(draft.key)"
        draft.labels.append(DBManager.getLabel(SystemLabel.draft.id)!)
        draft.fromAddress = "\(account.name) <\(account.username)\(Constants.domain)>"
        draft.secure = true
        draft.account = account
        DBManager.store(draft)
        self.email = draft
        
        let myContact = DBFactory.createAndStoreContact(email: "test@criptext.com", name: "Test", account: account)
        let contact = DBFactory.createAndStoreContact(email: "recipient@criptext.com", name: "Recipient", account: account)
        
        DBFactory.createAndStoreEmailContact(email: draft, contact: myContact, type: "from")
        DBFactory.createAndStoreEmailContact(email: draft, contact: contact, type: "to")
    }
    
    override func tearDown() {
        DBManager.destroy()
    }
    
    func testSendEmailEvenIfNoKeyBundle(){
        let compareResponse = ["criptextEmails": [["username": "recipient", "emails": []]], "subject": "test"] as [String : Any]
        let sendMailTask = SendMailAsyncTask(email: self.email, emailBody: "test", password: nil)
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
}
