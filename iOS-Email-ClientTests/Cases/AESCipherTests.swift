//
//  AESCipherTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 7/17/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
import SignalProtocolFramework
@testable import iOS_Email_Client
@testable import Firebase

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
    
    func testSuccessfullyGenerateKeyAES() {
        let password = "22222222"
        let saltData = Data(base64Encoded: "jxSwLannE0o=")!
        
        let keyData = AESCipher.generateKey(password: password, saltData: saltData)
        let keyB64 = keyData?.base64EncodedString() ?? ""
        XCTAssert(keyB64 == "u/StakI4hlPAYN/bZPM7gA==")
    }
    
    func testSuccessfullyEncryptSessionAES() {
        let password = "22222222"
        let saltData = Data(base64Encoded: "jxSwLannE0o=")!
        let ivData = Data(base64Encoded: "jb9s6ZN21XkyDC3/cz1YqQ==")!
        
        let keyData = AESCipher.generateKey(password: password, saltData: saltData)
        let keyB64 = keyData?.base64EncodedString() ?? ""
        XCTAssert(keyB64 == "u/StakI4hlPAYN/bZPM7gA==")
        
        let sessionData = sessionString.data(using: .utf8)!
        let encryptedData = AESCipher.encrypt(data: sessionData, keyData: keyData!, ivData: ivData, operation: kCCEncrypt)
        
        print(encryptedData?.base64EncodedString() ?? "nanai we")
        XCTAssert(encryptedData?.base64EncodedString() == encryptedSession)
    }
    
    func testGetPrivateKey(){
        let keyPair : ECKeyPair = Curve25519.generateKeyPair()
        let privateKey = keyPair.privateKey()!
        XCTAssert(privateKey.count > 0)
    }
    
    let sessionString = """
        {"identityKey":{"publicKey":"BRoCGAVTNQJAICDh86h/TvW2i1xIfBjvYn05cxh2nAwj","privateKey":"KBZDNUk4T/sAnxSQCS5S+iAKYCJePRMyaBQQTbyEC1w="},"registrationId":16077,"preKey":{"keyId":1,"publicKey":"BSkdPe6xZcj4UtHTy79/E4UL11LD0e1AR8unR+bQFmFW","privateKey":"eEnWZSfGr3DpUwdB7vgeE+7veitD8ER91Fhm/RPTR2w="},"signedPreKey":{"keyId":36,"publicKey":"BZc/9bEffvn2gpru7TV87rPi7kMO45xBiVQPXm2Ando6","privateKey":"8GN2C1WsA3jSQQLruDiee2aPp7WRizsGPb1I0Ew+IG0="}}
        """
    
    let encryptedSession = """
        4/fdI3VVRZkWzseYPC4qNzIOpOUxfldEmA40QIwCOC8vbdRG4cdwLJZxFaTreE8ObAcxG3vELv6K5nl0Ld0s+P1inVzS0MCeGILdg/XmzeCgkJQkkZmx+9SQ3hxZTl3u7OG24IWngbE/pMlYjT42G8M4G3oLtwRXxCcAk7H7VrVZobYmvOIDKIpg+TlWxpbihmNGC8Ro07j9+HaX4NLvq9NYLcEjmCig/ISuPy3DQTEU8gMN/0rAuc9+60/VvjCJdRuQgpd02JP5NLtxlGHQORcFnYwNJ2uDTp/Lf+pSUtfxGIsBsLLYhXYA6TeJqMQU+ZHvJRk/A1J8YnoI+l7/KQJA+HGOlvXWVG1xBwLbloyyN9fFflj5FMYgQ8EyeEW3hjpkjtBxfmrKFOVQm3LT0AOPEoheqw+emciOmnYdBjUvL3SNwW5BrebeX7gN7NtihEGGoxgMXtT7/khWX6P2uXOi94Y+kloQqIYiEpo5r3EK6R70IZl2nsc5ou77j8CuzqWzvXSNi/DXut4m0Ly/18jrItUZJoYIVYU2+KgOZwAPjhEN5Z570l7BSHW1TvjUlNqVDOtlQUWbBtwu8qO+PQ==
        """
}
