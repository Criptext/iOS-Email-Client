//
//  AcceptData.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 1/3/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class AcceptData {
    
    let authorizerName: String
    let authorizerType: Int
    let randomId: String
    let authorizerId: Int32
    
    init(authorizerName: String, authorizerType: Int, randomId: String, authorizerId: Int32) {
        self.authorizerName = authorizerName
        self.authorizerType = authorizerType
        self.randomId = randomId
        self.authorizerId = authorizerId
    }
    
    class func fromDictionary(_ params: [String: Any]) -> AcceptData? {
        guard let randomId = params["randomId"] as? String,
            let authorizerType = params["authorizerType"] as? Int,
            let authorizerName = params["authorizerName"] as? String,
            let authorizerId = params["authorizerId"] as? Int32 else {
                return nil
        }
        return AcceptData(authorizerName: authorizerName, authorizerType: authorizerType, randomId: randomId, authorizerId: authorizerId)
    }
}
