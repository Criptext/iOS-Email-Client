//
//  LoginData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/15/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class LoginData{
    var email: String
    var jwt: String?
    var randomId: String?
    var isTwoFactor = false
    var password: String?
    
    var username: String {
        return String(email.split(separator: "@")[0])
    }
    
    init(_ email: String){
        self.email = email
    }
}
