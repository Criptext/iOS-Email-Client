//
//  EventHandlerTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 6/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client
@testable import Firebase

class EventHandlerTests: XCTestCase {
    
    let myAccount = Account()
    let eventsString = """
        {"events":[{"rowid":1213,"cmd":1,"params":{\"messageType\":3,\"threadId\":\"<1528214090491.099438@jigl.com>\",\"senderDeviceId\":4,\"subject\":\"This is a big email\",\"from\":\"The Velvet <velvet@jigl.com>\",\"to\":\"velvet@jigl.com\",\"cc\":\"\",\"bcc\":\"\",\"messageId\":\"<1528214090491.099438@jigl.com>\",\"date\":\"2018-06-05 15:54:50\",\"metadataKey\":243,\"files\":[{\"timestamp\":\"2018-06-05T15:54:50.749Z\",\"token\":\"9eicctmj1xfji1v7bfp6w5fem0vii7\",\"read_only\":0,\"type\":\"image\",\"url\":\"https://services.criptext.com/viewer/9eicctmj1xfji1v7bfp6w5fem0vii7\",\"ephemeral\":0,\"status\":1,\"name\":\"Criptext_Image_2018_06_05.png\",\"size\":1318156},{\"timestamp\":\"2018-06-05T15:54:50.751Z\",\"token\":\"wzxathnpxg8ji1v74wzbczf5gvrbxt\",\"read_only\":0,\"type\":\"image\",\"url\":\"https://services.criptext.com/viewer/wzxathnpxg8ji1v74wzbczf5gvrbxt\",\"ephemeral\":0,\"status\":1,\"name\":\"Criptext_Image_2018_06_05.png\",\"size\":1180191}]}}]}
        """
    
    let opensString = """
        {"events":[{"rowid":43554,"cmd":2,"params":{\"type\":1,\"metadataKey\":243,\"from\":\"velvet\",\"date\":\"2018-06-05 15:54:50\"}}]}
        """
    
    override func setUp() {
        DBManager.signout()
        createSystemLabels()
    }
    
    func createExistingEmail(){
        let newEmail = Email()
        newEmail.key = 243
        DBManager.store(newEmail)
        let newContact = Contact()
        newContact.email = "velvet@jigl.com"
        newContact.displayName = "The Velvet"
        DBManager.store([newContact])
    }
    
    func createSystemLabels(){
        for systemLabel in SystemLabel.array {
            let newLabel = Label(systemLabel.description)
            newLabel.id = systemLabel.id
            newLabel.color = systemLabel.hexColor
            newLabel.type = "system"
            DBManager.store(newLabel)
        }
    }
    
    func testHandleNewEmailEventWithAttachments(){
        let eventsJSON = Utils.convertToDictionary(text: eventsString)
        let eventsArray = eventsJSON!["events"] as! [[String: Any]]
        let eventHandler = EventHandler(account: myAccount)
        eventHandler.apiManager = MockAPIManager.self
        eventHandler.signalHandler = MockSignalHandler.self
        let delegate = EventHandlerSpyDelegate()
        delegate.expectation = expectation(description: "Delegate Called Back")
        eventHandler.eventDelegate = delegate
        eventHandler.handleEvents(events: eventsArray)
        
        waitForExpectations(timeout: 10) { (testError) in
            if let error = testError {
                XCTFail("Error trying to call delegate \(error.localizedDescription)")
                return
            }
            
            guard let emails = delegate.delegateEmails else {
                XCTFail("Unable to handle mails")
                return
            }
            XCTAssert(emails.count == 1)
            XCTAssert(emails[0].key == 243)
            XCTAssert(emails[0].getFiles().count == 2)
        }
    }
    
    func testHandleOpenEventWithAttachments(){
        createExistingEmail()
        let eventsJSON = Utils.convertToDictionary(text: opensString)
        let eventsArray = eventsJSON!["events"] as! [[String: Any]]
        let eventHandler = EventHandler(account: myAccount)
        eventHandler.apiManager = MockAPIManager.self
        eventHandler.signalHandler = MockSignalHandler.self
        let delegate = EventHandlerSpyDelegate()
        delegate.expectation = expectation(description: "Delegate Called Back")
        eventHandler.eventDelegate = delegate
        eventHandler.handleEvents(events: eventsArray)
        
        waitForExpectations(timeout: 1) { (testError) in
            if let error = testError {
                XCTFail("Error trying to call delegate \(error.localizedDescription)")
                return
            }
            
            guard let opens = delegate.delegateOpens else {
                XCTFail("Unable to handle mails")
                return
            }
            XCTAssert(opens.count == 1)
            XCTAssert(opens[0].contact.email == "velvet@jigl.com")
        }
    }
    
}
