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
        {"events":[{"rowid":1213,"cmd":101,"params":{"messageType":3,"threadId":"<1528214090491.099438@jigl.com>","senderDeviceId":4,"subject":"This is a big email","from":"The Velvet <velvet@jigl.com>","to":"velvet@jigl.com","cc":"","bcc":"","messageId":"<1528214090491.099438@jigl.com>","date":"2018-06-05 15:54:50","metadataKey":243,"files":[{"timestamp":"2018-06-05T15:54:50.749Z","token":"9eicctmj1xfji1v7bfp6w5fem0vii7","read_only":0,"type":"image","url":"https://services.criptext.com/viewer/9eicctmj1xfji1v7bfp6w5fem0vii7","ephemeral":0,"status":1,"name":"Criptext_Image_2018_06_05.png","size":1318156},{"timestamp":"2018-06-05T15:54:50.751Z","token":"wzxathnpxg8ji1v74wzbczf5gvrbxt","read_only":0,"type":"image","url":"https://services.criptext.com/viewer/wzxathnpxg8ji1v74wzbczf5gvrbxt","ephemeral":0,"status":1,"name":"Criptext_Image_2018_06_05.png","size":1180191}]}}]}
        """
    
    let opensString = """
        {"events":[{"rowid":43554,"cmd":102,"params":{"type":7,"metadataKey":243,"from":"velvet","date":"2018-06-05 15:54:50"}}]}
        """
    
    override func setUp() {
        DBManager.destroy()
        DBManager.createSystemLabels()
    }
    
    func createExistingEmail(){
        let newEmail = Email()
        newEmail.key = 243
        DBManager.store(newEmail)
        let newContact = Contact()
        newContact.email = "velvet\(Constants.domain)"
        newContact.displayName = "The Velvet"
        DBManager.store([newContact])
    }
    
    func testHandleNewEmailEventWithAttachments(){
        let eventsJSON = Utils.convertToDictionary(text: eventsString)
        let eventsArray = eventsJSON!["events"] as! [[String: Any]]
        let eventHandler = EventHandler(account: myAccount)
        eventHandler.apiManager = MockAPIManager.self
        eventHandler.signalHandler = MockSignalHandler.self
        let expect = expectation(description: "Callback runs after handling events")
        eventHandler.handleEvents(events: eventsArray) { result in
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { (error) in
            if let error = error {
                XCTFail("Unable to execute callback with error : \(error)")
            }
        }
    }
    
    func testHandleOpenEventWithAttachments(){
        createExistingEmail()
        let eventsJSON = Utils.convertToDictionary(text: opensString)
        let eventsArray = eventsJSON!["events"] as! [[String: Any]]
        let eventHandler = EventHandler(account: myAccount)
        eventHandler.apiManager = MockAPIManager.self
        eventHandler.signalHandler = MockSignalHandler.self
        let expect = expectation(description: "Callback runs after handling events")
        eventHandler.handleEvents(events: eventsArray) { result in
            let opens = result.opens
            XCTAssert(opens.count == 1)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { (error) in
            if let error = error {
                XCTFail("Unable to execute callback with error : \(error)")
            }
        }
    }
    
}
