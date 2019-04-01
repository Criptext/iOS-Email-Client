//
//  APIManagerSpy.swift
//  iOS-Email-ClientTests
//
//  Created by Allisson on 3/12/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import XCTest
import Foundation
@testable import iOS_Email_Client

class APIManagerSpy: APIManager {
    
    static var expectation: XCTestExpectation?
    static var requestParams: [String: Any]? = nil
    
    override class func getKeysRequest(_ params: [String : Any], token: String, queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        completion(ResponseData.SuccessDictionary([
            "keyBundles": [[String: Any]](),
            "blacklistedKnownDevices": [[String: Any]]()
        ]))
    }
    
    override class func postMailRequest(_ params: [String : Any], token: String, queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        handleExpectation(params: params)
        completion(ResponseData.SuccessDictionary([
            "metadataKey": 1,
            "messageId": "<message_id>",
            "threadId": "<thread_id>"
        ]))
    }
    
    class func handleExpectation(params: [String: Any]) {
        guard let expect = expectation else {
            XCTFail("Unable to handle file upload")
            return
        }
        self.requestParams = params
        expect.fulfill()
    }
}
