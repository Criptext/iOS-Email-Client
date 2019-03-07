//
//  GZipTests.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Iñiguez on 10/10/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest

import SignalProtocolFramework
@testable import iOS_Email_Client
@testable import Firebase
import Gzip

class GZipTests: XCTestCase {
    
    func testSuccessfullyDecompress() {
        let filepath = CRBundle(for: GZipTests.self).path(forResource: "gunzipped", ofType: "txt")!
        guard let originalContent = try? String(contentsOfFile: filepath),
            let outputPath = try? AESCipher.compressFile(path: filepath, outputName: "hola.gz", compress: true),
            let finalPath = try? AESCipher.compressFile(path: outputPath, outputName: "bye.txt", compress: false),
            let content = try? String(contentsOfFile: finalPath) else {
                XCTFail()
                return
        }
        XCTAssert(originalContent == content)
    }
}
