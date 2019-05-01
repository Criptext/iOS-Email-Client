//
//  LoginData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/15/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class LoginData{
    var username: String
    var domain: String
    var jwt: String?
    var randomId: String?
    var isTwoFactor = false
    var password: String?
    
    var email: String {
        return "\(username)@\(domain)"
    }
    
    init(username: String, domain: String){
        self.username = username
        self.domain = domain
    }
}
