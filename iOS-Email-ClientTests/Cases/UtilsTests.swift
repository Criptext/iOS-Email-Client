//
//  UtilsTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 5/10/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client

class UtilsTests: XCTestCase {
    let fromString = "Smash Bros <smash@jigl.com>"
    
    func testGetUsernameFromEmailEventFormat(){
        let username = Utils.getUsernameFromEmailFormat(fromString)
        XCTAssert(username == "smash", "Username was not retrieved")
    }
    
}
