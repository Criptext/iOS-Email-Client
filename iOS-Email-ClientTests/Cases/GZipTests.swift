//
//  GZipTests.swift
//  iOS-Email-ClientTests
//
//  Created by Allisson on 10/10/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import XCTest

import SignalProtocolFramework
@testable import iOS_Email_Client
@testable import Firebase
import Gzip

class GZipTests: XCTestCase {
    
    func testSuccessfullyDecompress() {
        let filepath = Bundle(for: GZipTests.self).path(forResource: "gunzipped", ofType: "txt")!
        guard let outputPath = try? AESCipher.compressFile(path: filepath, outputName: "hola.gz", compress: true),
            let finalPath = try? AESCipher.compressFile(path: outputPath, outputName: "bye.txt", compress: false),
            let content = try? String(contentsOfFile: finalPath) else {
                XCTFail()
                return
        }
        let compressData = try! Data(contentsOf: URL(fileURLWithPath: outputPath))
        print("compressed size: \(compressData)")
        print("decompressed content: \(content)")
        XCTAssert(true)
    }
    
    func testSuccessfullyDecompress2() {
        let filepath = Bundle(for: GZipTests.self).path(forResource: "compressed", ofType: "gz")!
        guard let finalPath = try? AESCipher.compressFile(path: filepath, outputName: "bye.txt", compress: false),
            let content = try? String(contentsOfFile: finalPath) else {
                XCTFail()
                return
        }
        print("decompressed content: \(content)")
        XCTAssert(true)
    }
}
