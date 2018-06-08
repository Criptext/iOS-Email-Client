//
//  EventHandlerSpyDelegate.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 6/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
import Foundation
@testable import iOS_Email_Client

class EventHandlerSpyDelegate: EventHandlerDelegate {
    var expectation: XCTestExpectation?
    var delegateResult: [Email]?
    
    func didReceiveNewEmails(emails: [Email]) {
        guard let expect = expectation else {
            XCTFail("Unable to parse that one mail")
            return
        }
        delegateResult = emails
        expect.fulfill()
    }
}
