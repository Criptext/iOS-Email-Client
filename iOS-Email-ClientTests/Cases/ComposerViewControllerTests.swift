//
//  ComposerViewControllerTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 6/26/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client
@testable import Firebase

class ComposerViewControllerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let defaults = CriptextDefaults()
        defaults.removeConfig()
        DBManager.destroy()
        
        DBManager.createSystemLabels()
        let account = Account()
        account.username = "myself"
        account.deviceId = 1
        DBManager.store(account)
        
        defaults.activeAccount = account.username
    }
    
    override func tearDown() {
        super.tearDown()
        
        CriptextDefaults().removeConfig()
    }
    
    func testPassEmailToDelegate(){
        let testContact = Contact()
        testContact.email = "test@criptext.com"
        testContact.displayName = "Test"
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let composerVC = navComposeVC.viewControllers.first as! ComposeViewController
        let composerData = ComposerData()
        composerData.initToContacts = Array([testContact])
        composerData.initSubject = "test subject"
        composerData.initContent = "<p>This is a test</p>"
        composerVC.composerData = composerData
        
        composerVC.loadView()
        composerVC.viewDidLoad()
        
        composerVC.setupInitContacts()
        composerVC.prepareMail()
        guard let email = composerVC.composerData.emailDraft else {
            XCTFail("Unable to build email")
            return
        }
        
        XCTAssert(email.fromContact.email == "myself\(Constants.domain)")
        XCTAssert(email.subject == "test subject")
    }
    
    func testPassDraftToComposer() {
        
        let draft = DBFactory.createAndStoreEmail(key: 1234, preview: "This is a Draft", subject: "Draft", fromAddress: "test <test@criptext.com>")
        DBManager.addRemoveLabelsFromEmail(draft, addedLabelIds: [SystemLabel.draft.id], removedLabelIds: [])
        
        let testContact1 = DBFactory.createAndStoreContact(email: "test1@criptext.com", name: "Test1")
        let testContact2 = DBFactory.createAndStoreContact(email: "test2@criptext.com", name: "Test2")
        DBFactory.createAndStoreEmailContact(email: draft, contact: testContact1, type: "from")
        DBFactory.createAndStoreEmailContact(email: draft, contact: testContact2, type: "to")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let composerVC = navComposeVC.viewControllers.first as! ComposeViewController
        let composerData = ComposerData()
        composerData.initToContacts = Array(draft.getContacts(type: .to))
        composerData.initCcContacts = Array(draft.getContacts(type: .cc))
        composerData.initSubject = draft.subject
        composerData.emailDraft = draft
        if(!draft.threadId.isEmpty){
            composerData.threadId = draft.threadId
        }
        composerVC.composerData = composerData
        
        composerVC.loadView()
        composerVC.viewDidLoad()
        
        composerVC.setupInitContacts()
        composerVC.prepareMail()
        guard let email = composerVC.composerData.emailDraft else {
            XCTFail("Unable to build email")
            return
        }
        
        XCTAssert(draft.isInvalidated)
        XCTAssert(email.key != 1234)
    }
}
