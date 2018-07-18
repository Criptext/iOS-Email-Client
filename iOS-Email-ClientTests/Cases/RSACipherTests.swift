//
//  RSACipherTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 7/17/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client

class RSACipherTests: XCTestCase {
    func testSuccessfullyEncryptDecryptWithAES() {
        let expectedMessage = "este es un test"
        let keyData     = "12345678901234567890123456789012".data(using: .utf8)!
        let ivData      = "abcdefghijklmnop".data(using: .utf8)!
        let messageData = expectedMessage.data(using: .utf8)!
        
        let encryptedData = RSACipher.encrypt(data: messageData, keyData: keyData, ivData: ivData, operation: kCCEncrypt)!
        let decryptedData = RSACipher.encrypt(data: encryptedData, keyData: keyData, ivData: ivData, operation: kCCDecrypt)!
        
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)!
        XCTAssert(decryptedMessage == expectedMessage, "Decrypted message is WRONG!!!")
    }
}
