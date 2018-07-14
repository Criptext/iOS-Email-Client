//
//  FileManagerTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 7/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client

class FileManagerTests: XCTestCase {
    
    override func setUp() {
        DBManager.signout()
    }
    
    func testSuccessfullyUploadFile(){
        let delegate = FileManagerSpyDelegate()
        delegate.expectation = expectation(description: "Upload Called Back")
        let fileManager = CriptextFileManager()
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
            downloadManager.autoMerge = false
            downloadManager.delegate = downloadDelegate
            APIManager.commitFile(filetoken: filetoken, token: uploadManager.token){ error in
                guard error == nil else {
                    XCTFail("Unable to commit file")
                    return
                }
                sleep(10)
                let file = File()
                file.token = filetoken
                downloadManager.registerFile(file: file)
            }
            
            self.waitForExpectations(timeout: 15){ (testError) in
                if let error = testError {
                    XCTFail("Error trying to call delegate \(error.localizedDescription)")
                    return
                }
                
                guard uploadDelegate.success! else {
                    XCTFail("Unable to download file")
                    return
                }
                XCTAssert(downloadDelegate.file?.requestStatus == .finish)
            }
        }
    }
    
}
