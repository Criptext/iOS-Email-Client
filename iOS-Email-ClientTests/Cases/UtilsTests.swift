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
        
        let contactString5 = "<smash@jigl.com>,<pedro@criptext.com>"
        let contactMetadata5 = ContactUtils.getStringEmailName(contact: contactString5)
        XCTAssert(contactMetadata5.1 == "<smash@jigl.com>,", "name was not retrieved")
        XCTAssert(contactMetadata5.0 == "pedro@criptext.com", "email was not retrieved")
        
        let contactString6 = "Bros, Smash \"<smash@jigl.com>\""
        let contactMetadata6 = ContactUtils.getStringEmailName(contact: contactString6)
        XCTAssert(contactMetadata6.1 == "Bros, Smash", "name was not retrieved")
        XCTAssert(contactMetadata6.0 == "smash@jigl.com", "email was not retrieved")
        
        let contactString7 = "A,salame <salame@criptext.com>"
        let contactMetadata7 = ContactUtils.getStringEmailName(contact: contactString7)
        XCTAssert(contactMetadata7.1 == "A,salame", "name was not retrieved")
        XCTAssert(contactMetadata7.0 == "salame@criptext.com", "email was not retrieved")
    }
    
    func testSuccessfullyConvertArrayOfRecipientsFromString(){
        let contactsString = "Smash Bros <smash@jigl.com>,\"Bond,James\" <Bond.James@WillisTowersWatson.com>"
        let contacts = ContactUtils.prepareContactsStringArray(contactsString: contactsString)
        
        XCTAssert(contacts[0] == "Smash Bros <smash@jigl.com>", "name was not retrieved")
        XCTAssert(contacts[1] == "\"Bond,James\" <Bond.James@WillisTowersWatson.com>", "email was not retrieved: \(contacts[1])")
    }
    
}
