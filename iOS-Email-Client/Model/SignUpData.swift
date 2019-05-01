//
//  SignUpData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class SignUpData{
    var username: String
    var domain: String
    var password: String
    var fullname: String
    var optionalEmail: String?
    var identifier: String{
        return username
    }
    var deviceId: Int = 1
    var token: String = ""
    var refreshToken: String?
    
    init(username: String, password: String, domain: String, fullname: String, optionalEmail: String?){
        self.username = username
        self.domain = domain
        self.password = password
        self.fullname = fullname
        self.optionalEmail = optionalEmail
    }
    
    func buildDataForRequest(publicKeys: [String: Any]) -> [String : Any]{
        var data = [
            "recipientId": username,
            "password": password.sha256()!,
            "name": fullname,
            "keybundle": publicKeys
            ] as [String : Any]
        if(optionalEmail != nil && !optionalEmail!.isEmpty){
            data["recoveryEmail"] = optionalEmail
        }
        
        return data
    }
    
    class func createAccount(from signupData: SignUpData) -> Account {
        let myAccount = Account()
        myAccount.username = signupData.username
        myAccount.domain = "@\(signupData.domain)" == Env.domain ? nil : signupData.domain
        myAccount.name = signupData.fullname
        myAccount.jwt = signupData.token
        myAccount.regId = 0
        myAccount.identityB64 = ""
        myAccount.deviceId = signupData.deviceId
        myAccount.buildCompoundKey()
        return myAccount
    }
}
