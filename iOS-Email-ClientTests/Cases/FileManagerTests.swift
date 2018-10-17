//
//  FileManagerTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 7/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client
@testable import Firebase

class FileManagerTests: XCTestCase {
    
    var token: String {
        return ("k17mevsfe3u0feskuhb6:xaov68v03il7r1pac61x").data(using: .utf8)!.base64EncodedString()
    }
    
    override func setUp() {
        DBManager.signout()
    }
    
    func testSuccessfullyUploadFile(){
        let delegate = FileManagerSpyDelegate()
        delegate.expectation = expectation(description: "Upload Called Back")
        let fileManager = CriptextFileManager()
        fileManager.token = token
        fileManager.delegate = delegate
        let filepath = Bundle(for: FileManagerTests.self).path(forResource: "criptextlogo", ofType: "png")!
        fileManager.registerFile(filepath: filepath, name: "criptextlogo.png", mimeType: "image/png")
        
        waitForExpectations(timeout: 15) { (testError) in
            if let error = testError {
                XCTFail("Error trying to call delegate \(error.localizedDescription)")
                return
            }
            
            guard delegate.success! else {
                XCTFail("Unable to upload file")
                return
            }
            XCTAssert(delegate.file?.requestStatus == .finish)
        }
    }
    
    func testSuccessfullyDownloadFile(){
        let uploadDelegate = FileManagerSpyDelegate()
        uploadDelegate.expectation = expectation(description: "Delegate Called Back")
        let uploadManager = CriptextFileManager()
        uploadManager.token = self.token
        uploadManager.delegate = uploadDelegate
        let filepath = Bundle(for: FileManagerTests.self).path(forResource: "criptextlogo", ofType: "png")!
        uploadManager.registerFile(filepath: filepath, name: "criptextlogo.png", mimeType: "image/png")
        
        waitForExpectations(timeout: 40) { (testError) in
            if let error = testError {
                XCTFail("Error trying to call delegate \(error.localizedDescription)")
                return
            }
            
            guard uploadDelegate.success! else {
                XCTFail("Unable to upload file")
                return
            }
            XCTAssert(uploadDelegate.file?.requestStatus == .finish)
            let filetoken = uploadDelegate.file!.token
            
            let downloadDelegate = FileManagerSpyDelegate()
            downloadDelegate.expectation = self.expectation(description: "Download Delegate Called Back")
            let downloadManager = CriptextFileManager()
            downloadManager.delegate = downloadDelegate
            downloadManager.token = self.token
            APIManager.commitFile(filetoken: filetoken, token: uploadManager.token){ error in
                guard error == nil else {
                    XCTFail("Unable to commit file")
                    return
                }
                sleep(10)
                let file = File()
                file.token = filetoken
                file.name = "criptextlogo2.png"
                downloadManager.registerFile(file: file)
            }
            
            self.waitForExpectations(timeout: 20){ (testError) in
                if let error = testError {
                    XCTFail("Error trying to call delegate \(error.localizedDescription)")
                    return
                }
                
                guard downloadDelegate.success! else {
                    XCTFail("Unable to download file")
                    return
                }
                XCTAssert(downloadDelegate.file?.requestStatus == .finish)
            }
        }
    }
    
    func testSuccessfullyUploadEncryptedFile(){
        let keyData     = "12345678901234567890123456789012".data(using:String.Encoding.utf8)!
        let ivData      = "abcdefghijklmnop".data(using:String.Encoding.utf8)!
        
        let delegate = FileManagerSpyDelegate()
        delegate.expectation = expectation(description: "Upload Called Back")
        let fileManager = CriptextFileManager()
        fileManager.token = token
        fileManager.setEncryption(id: 0, key: keyData, iv: ivData)
        fileManager.delegate = delegate
        let filepath = Bundle(for: FileManagerTests.self).path(forResource: "criptextlogo", ofType: "png")!
        fileManager.registerFile(filepath: filepath, name: "criptextlogo.png", mimeType: "image/png")
        
        waitForExpectations(timeout: 15) { (testError) in
            if let error = testError {
                XCTFail("Error trying to call delegate \(error.localizedDescription)")
                return
            }
            
            guard delegate.success! else {
                XCTFail("Unable to upload file")
                return
            }
            XCTAssert(delegate.file?.requestStatus == .finish)
        }
    }
    
    func testSuccessfullyDownloadEncryptedFile(){
        let keyData     = AESCipher.generateRandomBytes()
        let ivData      = AESCipher.generateRandomBytes()
        
        let uploadDelegate = FileManagerSpyDelegate()
        uploadDelegate.expectation = expectation(description: "Delegate Called Back")
        let uploadManager = CriptextFileManager()
        uploadManager.setEncryption(id: 0, key: keyData, iv: ivData)
        uploadManager.delegate = uploadDelegate
        uploadManager.token = token
        let filepath = Bundle(for: FileManagerTests.self).path(forResource: "criptextlogo", ofType: "png")!
        uploadManager.registerFile(filepath: filepath, name: "criptextlogo.png", mimeType: "image/png")
        
        waitForExpectations(timeout: 40) { (testError) in
            if let error = testError {
                XCTFail("Error trying to call upload delegate \(error.localizedDescription)")
                return
            }
            
            guard uploadDelegate.success! else {
                XCTFail("Unable to upload file")
                return
            }
            XCTAssert(uploadDelegate.file?.requestStatus == .finish)
            let filetoken = uploadDelegate.file!.token
            
            let downloadDelegate = FileManagerSpyDelegate()
            downloadDelegate.expectation = self.expectation(description: "Download Delegate Called Back")
            let downloadManager = CriptextFileManager()
            downloadManager.token = self.token
            downloadManager.setEncryption(id: 1, key: keyData, iv: ivData)
            downloadManager.delegate = downloadDelegate
            APIManager.commitFile(filetoken: filetoken, token: uploadManager.token){ error in
                guard error == nil else {
                    XCTFail("Unable to commit file")
                    return
                }
                sleep(10)
                let file = File()
                file.token = filetoken
                file.name = "criptextlogo\(Date().timeIntervalSince1970).png"
                file.emailId = 1
                downloadManager.registerFile(file: file)
            }
            
            self.waitForExpectations(timeout: 40){ (testError) in
                if let error = testError {
                    XCTFail("Error trying to call download delegate \(error.localizedDescription)")
                    return
                }
                
                guard downloadDelegate.success! else {
                    XCTFail("Unable to download file")
                    return
                }
                XCTAssert(downloadDelegate.file?.requestStatus == .finish)
                let localFileSize = try! Data(contentsOf: URL(fileURLWithPath: filepath)).count
                let downloadedFileSize = try? Data(contentsOf: URL(fileURLWithPath: downloadDelegate.file!.filepath)).count 
                XCTAssert(localFileSize == downloadedFileSize)
            }
        }
    }
    
}
