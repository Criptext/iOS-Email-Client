//
//  AESCipherTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 7/17/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client

class AESCipherTests: XCTestCase {
    func testSuccessfullyEncryptDecryptWithAES() {
        let expectedMessage = "este es un test"
        let keyData     = AESCipher.generateRandomBytes()
        let ivData      = AESCipher.generateRandomBytes()
        let messageData = expectedMessage.data(using: .utf8)!
        
        let encryptedData = AESCipher.encrypt(data: messageData, keyData: keyData, ivData: ivData, operation: kCCEncrypt)!
        let decryptedData = AESCipher.encrypt(data: encryptedData, keyData: keyData, ivData: ivData, operation: kCCDecrypt)!
        
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)!
        XCTAssert(decryptedMessage == expectedMessage, "Decrypted message is WRONG!!!")
    }
}
