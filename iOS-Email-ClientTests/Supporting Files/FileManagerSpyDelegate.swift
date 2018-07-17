//
//  FileManagerSpyDelegate.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 7/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest
import Foundation
@testable import iOS_Email_Client

class FileManagerSpyDelegate: CriptextFileDelegate {
    var expectation: XCTestExpectation?
    var file: File?
    var success: Bool?
    
    func uploadProgressUpdate(file: File, progress: Int) {
        //NOT NEEDED
    }
    
    func finishRequest(file: File, success: Bool) {
        guard let expect = expectation else {
            XCTFail("Unable to handle file upload")
            return
        }
        self.file = file
        self.success = success
        expect.fulfill()
    }
}
