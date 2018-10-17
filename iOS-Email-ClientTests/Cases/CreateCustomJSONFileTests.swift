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
    {"table":"email","object":{"content":"test 1","messageId":"<dsfsfd.dsfsdfs@ddsfs.fsdfs>","isMuted":false,"threadId":"<dsfsfd.dsfsdfs@ddsfs.fsdfs>","unread":true,"secure":true,"preview":"test 1","status":3,"date":"2018-07-17 15:09:36","key":123,"subject":"","id":1}}
    {"table":"email_label","object":{"labelId":1,"emailId":1}}
    {"table":"email_contact","object":{"type":"from","contactId":2,"emailId":1,"id":1}}
    {"table":"email_contact","object":{"type":"to","contactId":1,"emailId":1,"id":2}}
    {"table":"file","object":{"name":"test.pdf","status":1,"emailId":123,"id":1,"token":"","readOnly":false,"size":0,"date":"2018-07-17 15:09:36","mimeType":""}}
    {"table":"filekey","object":{"id":1,"key":"fgsfgfgsfdafa","iv":afdsfsagdfgsdf","emailId":1}}
    """
    
    override func setUp() {
        super.setUp()
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "activeAccount")
        
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
    
    func testSuccessfullyParseDate(){
        let originalDateString = "2018-09-21 09:33:05"
        let date = EventData.convertToDate(dateString: originalDateString)
        
        let dateString = DateUtils().date(toServerString: date)!
        print(dateString)
        
        let parsedDate = EventData.convertToDate(dateString: dateString)
        print(DateUtils().date(toServerString: parsedDate)!)
        
        XCTAssert(DateUtils().date(toServerString: parsedDate)! == dateString)
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
            print(self.desiredDBText)
            print("SPACE")
            print(fileString)
            XCTAssert(fileString.count == self.desiredDBText.count)
            
            let outputPath = AESCipher.streamEncrypt(path: myUrl.path, outputName: "secure-db", keyData: self.keyData, ivData: self.ivData, operation: kCCEncrypt)
            
            XCTAssert(outputPath != nil)
            
            let decryptedPath = AESCipher.streamEncrypt(path: outputPath!, outputName: "decrypted-db", keyData: self.keyData, ivData: nil, operation: kCCDecrypt)
            
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
    
    
    func testSuccessfullyCreateDBFromFile(){
        let expect = expectation(description: "Callback runs after generating db file")
        
        CreateCustomJSONFileAsyncTask().start { (error, url) in
            guard let myUrl = url else {
                XCTFail("unable to process db with error: \(String(describing: error))")
                return
            }
            let fileData = try! Data(contentsOf: myUrl)
            let fileString = String(data: fileData, encoding: .utf8)!
            XCTAssert(fileString.count == self.desiredDBText.count)
            
            DBManager.destroy()
            let streamReader = StreamReader(url: myUrl, delimeter: "\n", encoding: .utf8, chunkSize: 1024)
            var dbRows = [[String: Any]]()
            var maps = DBManager.LinkDBMaps.init(emails: [Int: Int](), contacts: [Int: String]())
            while let line = streamReader?.nextLine() {
                guard let row = Utils.convertToDictionary(text: line) else {
                    continue
                }
                dbRows.append(row)
                if dbRows.count >= 30 {
                    DBManager.insertBatchRows(rows: dbRows, maps: &maps)
                    dbRows.removeAll()
                }
            }
            DBManager.insertBatchRows(rows: dbRows, maps: &maps)
            
            let email = DBManager.getMail(key: 123)
            XCTAssert(email != nil)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2) { (error) in
            if let error = error {
                XCTFail("Unable to execute callback with error : \(error)")
            }
        }
    }
}
