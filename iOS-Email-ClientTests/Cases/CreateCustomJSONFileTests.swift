//
//  CreateCustomJSONFileTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 7/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client
@testable import Firebase

class CreateCustomJSONFileTests: XCTestCase {
    
    let keyData     = AESCipher.generateRandomBytes()
    let ivData      = AESCipher.generateRandomBytes()
    
    let desiredDBText = """
    {"table":"contact","object":{"id":1,"name":"Test 1","email":"test1@criptext.com"}}
    {"table":"contact","object":{"id":2,"name":"Test 2","email":"test2@criptext.com"}}
    {"table":"label","object":{"visible":true,"id":1,"text":"Test 1","type":"custom","color":"fff000"}}
    {"table":"label","object":{"visible":true,"id":2,"text":"Test 2","type":"custom","color":"ff00ff"}}
    {"table":"email","object":{"content":"test 1","messageId":"<dsfsfd.dsfsdfs@ddsfs.fsdfs>","isMuted":false,"threadId":"<dsfsfd.dsfsdfs@ddsfs.fsdfs>","unread":true,"secure":true,"preview":"test 1","delivered":3,"date":"2018-07-17T15:09:36.000Z","metadataKey":123,"subject":""}}
    {"table":"emailLabel","object":{"labelId":1,"emailId":123}}
    {"table":"emailContact","object":{"type":"from","contactId":2,"emailId":123}}
    {"table":"emailContact","object":{"type":"to","contactId":1,"emailId":123}}
    {"table":"file","object":{"name":"test.pdf","status":1,"emailId":123,"id":1,"token":"","readOnly":0,"size":0,"date":"2018-07-17T15:09:36.000Z"}}
    {"table":"fileKey","object":{"id":1,"key":"fgsfgfgsfdafa:afdsfsagdfgsdf","emailId":123}}
    """
    
    override func setUp() {
        super.setUp()
        
        DBManager.destroy()
        let newLabel = Label("Test 1")
        newLabel.id = 1
        newLabel.color =  "fff000"
        newLabel.type = "custom"
        DBManager.store(newLabel)
        let newLabel2 = Label("Test 2")
        newLabel2.id = 2
        newLabel2.color =  "ff00ff"
        newLabel2.type = "custom"
        DBManager.store(newLabel2)
        
        let testContact = Contact()
        testContact.email = "test1@criptext.com"
        testContact.displayName = "Test 1"
        let testContact2 = Contact()
        testContact2.email = "test2@criptext.com"
        testContact2.displayName = "Test 2"
        DBManager.store([testContact, testContact2])
        
        let email = Email()
        email.content = "test 1"
        email.preview = "test 1"
        email.messageId = "<dsfsfd.dsfsdfs@ddsfs.fsdfs>"
        email.threadId = "<dsfsfd.dsfsdfs@ddsfs.fsdfs>"
        email.key = 123
        email.date = Date(timeIntervalSince1970: 1531840176)
        DBManager.store(email)
        
        DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [1], removedLabelIds: [])
        
        let emailContact = EmailContact()
        emailContact.compoundKey = "\(email.key):\(testContact2.email)\(ContactType.from.rawValue)"
        emailContact.email = email
        emailContact.contact = testContact2
        emailContact.type = ContactType.from.rawValue
        let emailContact2 = EmailContact()
        emailContact.compoundKey = "\(email.key):\(testContact.email)\(ContactType.to.rawValue)"
        emailContact2.email = email
        emailContact2.contact = testContact
        emailContact2.type = ContactType.to.rawValue
        DBManager.store([emailContact, emailContact2])
        
        let file = File()
        file.name = "test.pdf"
        file.emailId = 123
        file.date = Date(timeIntervalSince1970: 1531840176)
        DBManager.store(file)
        
        let fileKey = FileKey()
        fileKey.id = 1
        fileKey.emailId = 123
        fileKey.key = "fgsfgfgsfdafa:afdsfsagdfgsdf"
        DBManager.store([fileKey])
    }
    
    func testSuccessfullyCreateEncryptDecryptDBFile(){
        let expect = expectation(description: "Callback runs after generating db file")

        CreateCustomJSONFileAsyncTask().start { (error, url) in
            guard let myUrl = url else {
                XCTFail("unable to process db with error: \(String(describing: error))")
                return
            }
            let fileData = try! Data(contentsOf: myUrl)
            let fileString = String(data: fileData, encoding: .utf8)!
            XCTAssert(self.desiredDBText == fileString)
            
            let outputPath = AESCipher.streamEncrypt(path: myUrl.path, outputName: "secure-db", keyData: self.keyData, ivData: self.ivData, operation: kCCEncrypt)
            
            XCTAssert(outputPath != nil)
            
            let decryptedPath = AESCipher.streamEncrypt(path: outputPath!, outputName: "decrypted-db", keyData: self.keyData, ivData: self.ivData, operation: kCCDecrypt)
            
            XCTAssert(decryptedPath != nil)
            
            let decryptedData = try! Data(contentsOf: URL(fileURLWithPath: decryptedPath!))
            let decryptedString = String(data: decryptedData, encoding: .utf8)!
            
            XCTAssert(decryptedString == fileString)
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10) { (error) in
            if let error = error {
                XCTFail("Unable to execute callback with error : \(error)")
            }
        }
    }
    
}
