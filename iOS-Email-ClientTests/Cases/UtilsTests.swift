//
//  UtilsTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 5/10/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client
@testable import Firebase

class UtilsTests: XCTestCase {
    let fromString = "Smash Bros <smash@jigl.com>"
    
    func testGetUsernameFromEmailEventFormat(){
        let username = Utils.getUsernameFromEmailFormat(fromString)
        XCTAssert(username == "smash", "Username was not retrieved")
    }
    
    func testGetEmailAndNameFromDifferentFormats(){
        let contactString1 = "Smash Bros <smash@jigl.com>"
        let contactMetadata1 = ContactUtils.getStringEmailName(contact: contactString1)
        XCTAssert(contactMetadata1.1 == "Smash Bros", "name was not retrieved")
        XCTAssert(contactMetadata1.0 == "smash@jigl.com", "email was not retrieved")
        
        let contactString2 = "<smash@jigl.com>"
        let contactMetadata2 = ContactUtils.getStringEmailName(contact: contactString2)
        XCTAssert(contactMetadata2.1 == "smash", "name was not retrieved")
        XCTAssert(contactMetadata2.0 == "smash@jigl.com", "email was not retrieved")
        
        let contactString3 = "smash@jigl.com"
        let contactMetadata3 = ContactUtils.getStringEmailName(contact: contactString3)
        XCTAssert(contactMetadata3.1 == "smash", "name was not retrieved")
        XCTAssert(contactMetadata3.0 == "smash@jigl.com", "email was not retrieved")
        
        let contactString4 = "\"smash@jigl.com\""
        let contactMetadata4 = ContactUtils.getStringEmailName(contact: contactString4)
        XCTAssert(contactMetadata4.1 == "smash", "name was not retrieved")
        XCTAssert(contactMetadata4.0 == "smash@jigl.com", "email was not retrieved")
    }
    
}
