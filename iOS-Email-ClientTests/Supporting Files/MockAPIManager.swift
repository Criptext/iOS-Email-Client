//
//  MockAPIManager.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 6/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
@testable import iOS_Email_Client

class MockAPIManager: APIManager {
    override class func getEmailBody(metadataKey: Int, token: String, completion: @escaping ((ResponseData) -> Void)){
        completion(ResponseData.Body("ytw8v0ntriuhtkirglsdfnakncbdjshndls"))
    }
    
    override class func acknowledgeEvents(eventIds: [Int32], token: String){
        return
    }
    
}
