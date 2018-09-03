//
//  CriptextError.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/17/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class CriptextError : Error {
    let code: ErrorCode
    
    init(code: ErrorCode){
        self.code = code
    }
    var description : String {
        get {
            return "Error Code \(code) : \(code.description)"
        }
    }
    var localizedDescription: String {
        get {
            return description
        }
    }
}

enum ErrorCode: Int {
    case accountNotCreated = 1
    case invalidUsername = 2
    case noValidResponse = 100
    case bodyUnsent = 3
    case loggedOut = 4
    case timeout = 5
    
    var description: String {
        switch self {
        case .accountNotCreated:
            return "Unable to create your Account"
        case .invalidUsername:
            return "Username already exists"
        case .noValidResponse:
            return "Couldn't get a valid response"
        case .bodyUnsent:
            return "Email was unsent"
        case .loggedOut:
            return "This device was remotely logged out"
        case .timeout:
            return "Connection Timeout!"
        }
    }
}
