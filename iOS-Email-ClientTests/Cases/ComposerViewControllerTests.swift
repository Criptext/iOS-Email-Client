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
    
    var composerVC: ComposeViewController!
    
    override func setUp() {
        super.setUp()
        
        guard composerVC == nil else {
            return
        }
        DBManager.destroy()
        for systemLabel in SystemLabel.array {
            let newLabel = Label(systemLabel.description)
            newLabel.id = systemLabel.id
            newLabel.color = systemLabel.hexColor
            newLabel.type = "system"
            DBManager.store(newLabel)
        }
        let account = Account()
        account.username = "myself"
        account.deviceId = 1
        DBManager.store(account)
        
        let defaults = UserDefaults.standard
        defaults.set(account.username, forKey: "activeAccount")
        
        let testContact = Contact()
        testContact.email = "test@criptext.com"
        testContact.displayName = "Test"
    
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        composerVC = navComposeVC.viewControllers.first as! ComposeViewController
        let composerData = ComposerData()
        composerData.initToContacts = Array([testContact])
        composerData.initSubject = "test subject"
        composerData.initContent = "<p>This is a test</p>"
        composerVC.composerData = composerData
        
        composerVC.loadView()
        composerVC.viewDidLoad()
    }
    
    func testPassEmailToDelegate(){
        composerVC.setupInitContacts()
        composerVC.prepareMail()
        guard let email = composerVC.composerData.emailDraft else {
            XCTFail("Unable to build email")
            return
        }
        
        XCTAssert(email.fromContact.email == "myself\(Constants.domain)")
        XCTAssert(email.subject == "test subject")
    }
}
