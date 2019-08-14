//
//  SignUpTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Iniguez on 2/27/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

import XCTest
@testable import iOS_Email_Client
@testable import Firebase

class SignUpTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        DBManager.destroy()
    }
    
    func testUserNameInputShortInvalid(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let signupVC = storyboard.instantiateViewController(withIdentifier: "signupview") as! SignUpViewController
        signupVC.loadView()
        
        signupVC.usernameTextField.text = "t"
        signupVC.inputEditEnd(signupVC.usernameTextField)
        
        XCTAssert(signupVC.usernameTextField.status == .invalid)
    }
    
    func testUserNameInputHasSpacesInvalid(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let signupVC = storyboard.instantiateViewController(withIdentifier: "signupview") as! SignUpViewController
        signupVC.loadView()
        
        signupVC.usernameTextField.text = "t t"
        signupVC.inputEditEnd(signupVC.usernameTextField)
        
        XCTAssert(signupVC.usernameTextField.status == .invalid)
    }
    
    func testUserNameInputHasInvalidCharsInvalid(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let signupVC = storyboard.instantiateViewController(withIdentifier: "signupview") as! SignUpViewController
        signupVC.loadView()
        
        signupVC.usernameTextField.text = "que%dice"
        signupVC.inputEditEnd(signupVC.usernameTextField)
        
        XCTAssert(signupVC.usernameTextField.status == .invalid)
    }
    
    func testUserNameInputHasDotAtBeginningInvalid(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let signupVC = storyboard.instantiateViewController(withIdentifier: "signupview") as! SignUpViewController
        signupVC.loadView()
        
        signupVC.usernameTextField.text = ".test"
        signupVC.inputEditEnd(signupVC.usernameTextField)
        
        XCTAssert(signupVC.usernameTextField.status == .invalid)
    }
    
    func testEmailInvalid(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let signupVC = storyboard.instantiateViewController(withIdentifier: "signupview") as! SignUpViewController
        signupVC.loadView()
        
        signupVC.emailTextField.text = "test@criptext.com"
        signupVC.inputEditEnd(signupVC.emailTextField)
        
        XCTAssert(signupVC.emailTextField.status == .valid)
    }
    
    func testEmailIsValid(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let signupVC = storyboard.instantiateViewController(withIdentifier: "signupview") as! SignUpViewController
        signupVC.loadView()
        
        signupVC.emailTextField.text = "te st@criptext.com"
        signupVC.inputEditEnd(signupVC.emailTextField)
        
        XCTAssert(signupVC.emailTextField.status == .invalid)
    }
    
    func testUsernameIsValid(){
        let usernames = ["test007", "001", "0v0", "ovo", "te..st", "test123test"]
        for username in usernames {
            XCTAssert(Utils.isValidUsername(username), "\(username) invalid")
        }
    }
    
    func testUsernameIsInvalid(){
        let usernames = ["t...est", "%test%", "t3st!", "test.", "t"]
        for username in usernames {
            XCTAssert(!Utils.isValidUsername(username), "\(username) valid")
        }
    }
    
}
