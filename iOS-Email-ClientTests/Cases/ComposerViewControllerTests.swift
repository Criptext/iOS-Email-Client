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
    
    var emailString = """
    {"deviceId": 10, "type": "to", "body": "MwgLEiEFYdp7w03fKYi1EzQorTLeo6Ltdr7YdMJrqJxWTPTymhkaIQXpYvZ3X6Te9HxglJ5dJVoDqaKGNBsVXp9pb0avv+9OEiJCMwohBTcwupSpytHYsa0JQkCWpD7xN2evMl3sWly9TxihRdoNEAEYACIQxRpkh7PlNjZFvC7FJtkINzEQVcd4o1qoKJlUMGM=", "messageType": 3, "recipientId": "lucifer"}
    """
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
        
        let groupDefaults = UserDefaults.init(suiteName: Env.groupApp)!
        groupDefaults.set(account.username, forKey: "activeAccount")
        
        let testContact = Contact()
        testContact.email = "test@criptext.com"
        testContact.displayName = "Test"
    
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        composerVC = navComposeVC.viewControllers.first as? ComposeViewController
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
