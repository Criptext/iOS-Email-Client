//
//  SignalTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Iniguez on 2/25/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import XCTest

import SignalProtocolFramework
@testable import iOS_Email_Client
import Gzip

class SignalTests: XCTestCase {
    
    internal struct Message {
        var content: String
        var messageType: MessageType
        var original: String
    }
    
    override func setUp() {
        super.setUp()
        DBManager.destroy()
    }
    
    func testEncryptedAndDecryptMessageSuccessfully() {
        let alice = Dummy(recipientId: "alice")
        let bob = Dummy(recipientId: "bob", deviceId: 10)
        
        TestSignalHandler.buildSession(recipientId: bob.recipientId, deviceId: bob.deviceId, keys: bob.getKeyBundle(), store: alice.store)
        
        let encrypted = TestSignalHandler.encryptMessage(body: "Hello World", deviceId: bob.deviceId, recipientId: bob.recipientId, store: alice.store)
        
        let bobPlaintextString = TestSignalHandler.decryptMessage(encrypted.0, messageType: encrypted.1, store: bob.store, recipientId: alice.recipientId, deviceId: alice.deviceId)
        
        XCTAssert(bobPlaintextString == "Hello World")
    }
    
    func testBobReceives50MessagesSuccessfully() {
        let alice = Dummy(recipientId: "alice")
        let bob = Dummy(recipientId: "bob", deviceId: 10)
        var bobMessages = [Message]()
        TestSignalHandler.buildSession(recipientId: bob.recipientId, deviceId: bob.deviceId, keys: bob.getKeyBundle(), store: alice.store)
        
        for index in 1...50 {
            let message = "Hello World \(index)"
            let encrypted = TestSignalHandler.encryptMessage(body: message, deviceId: bob.deviceId, recipientId: bob.recipientId, store: alice.store)
            bobMessages.append(Message(content: encrypted.0, messageType: encrypted.1, original: message))
        }
        
        for message in bobMessages {
            let bobPlaintextString = TestSignalHandler.decryptMessage(message.content, messageType: message.messageType, store: bob.store, recipientId: alice.recipientId, deviceId: alice.deviceId)
            XCTAssert(bobPlaintextString == message.original)
        }
    }
    
    func testExchange50MessagesSuccessfully() {
        let alice = Dummy(recipientId: "alice")
        let bob = Dummy(recipientId: "bob", deviceId: 10)
        TestSignalHandler.buildSession(recipientId: bob.recipientId, deviceId: bob.deviceId, keys: bob.getKeyBundle(), store: alice.store)
        
        for index in 1...50 {
            let message = "Hello Bob \(index)"
            let encrypted = TestSignalHandler.encryptMessage(body: message, deviceId: bob.deviceId, recipientId: bob.recipientId, store: alice.store)
            
            let bobDecrypted = TestSignalHandler.decryptMessage(encrypted.0, messageType: encrypted.1, store: bob.store, recipientId: alice.recipientId, deviceId: alice.deviceId)
            XCTAssert(bobDecrypted == message)
            
            let replyMessage = "Hi Alice \(index)"
            let replyEncrypted = TestSignalHandler.encryptMessage(body: replyMessage, deviceId: alice.deviceId, recipientId: alice.recipientId, store: bob.store)
            
            let aliceDecrypted = TestSignalHandler.decryptMessage(replyEncrypted.0, messageType: replyEncrypted.1, store: alice.store, recipientId: bob.recipientId, deviceId: bob.deviceId)
            XCTAssert(aliceDecrypted == replyMessage)
        }
    }
    
    func testSendMessageToInMemoryUser(){
        let signupData = SignUpData(username: "test", password: "123", domain: "criptext.com", fullname: "Test", optionalEmail: nil)
        signupData.token = "test"
        let account = SignUpData.createAccount(from: signupData)
        let bundle = CRBundle(account: account)
        bundle.generateKeys()
        DBManager.update(account: account, jwt: "", refreshToken: "", regId: bundle.regId, identityB64: bundle.identity)
        let bob = Dummy(recipientId: "bob", deviceId: 10)
        SignalHandler.buildSession(recipientId: bob.recipientId, deviceId: bob.deviceId, keys: bob.getKeyBundle(), account: account)
        
        let message = "Hello World"
        let encrypted = SignalHandler.encryptMessage(body: message, deviceId: bob.deviceId, recipientId: bob.recipientId, account: account)
        
        let bobDecrypted = TestSignalHandler.decryptMessage(encrypted.0, messageType: encrypted.1, store: bob.store, recipientId: account.username, deviceId: Int32(account.deviceId))
        XCTAssert(bobDecrypted == message)
    }
    
    func testRecieveMessageFromInMemoryUser(){
        let signupData = SignUpData(username: "test", password: "123", domain: "criptext.com", fullname: "Test", optionalEmail: nil)
        signupData.token = "test"
        let account = SignUpData.createAccount(from: signupData)
        let bundle = CRBundle(account: account)
        var preKeys = bundle.generateKeys()
        DBManager.update(account: account, jwt: "", refreshToken: "", regId: bundle.regId, identityB64: bundle.identity)
        preKeys["preKey"] = (preKeys["preKeys"] as! [[String: Any]]).first!
        
        let bob = Dummy(recipientId: "bob", deviceId: 10)
        TestSignalHandler.buildSession(recipientId: account.username, deviceId: Int32(account.deviceId), keys: preKeys, store: bob.store)
        
        let message = "Hello World"
        let encrypted = TestSignalHandler.encryptMessage(body: message, deviceId: Int32(account.deviceId), recipientId: account.username, store: bob.store)
        
        let aliceDecrypted = SignalHandler.decryptMessage(encrypted.0, messageType: encrypted.1, account: account, recipientId: bob.recipientId, deviceId: bob.deviceId)
        XCTAssert(aliceDecrypted == message)
    }
}

