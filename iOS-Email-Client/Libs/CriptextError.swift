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
    let message: String?
    
    init(code: ErrorCode){
        self.code = code
        self.message = nil
    }
    
    init(message: String){
        self.code = .custom
        self.message = message
    }
    
    var description : String {
        get {
            guard let errorMessage = message else {
                return code.description
            }
            return errorMessage
        }
    }
    var localizedDescription: String {
        get {
            return description
        }
    }
}

enum ErrorCode {
    case singUpFailure
    case invalidUsername
    case noValidResponse
    case missingData
    case loggedOut
    case timeout
    case offline
    case custom
    
    var description: String {
        switch self {
        case .singUpFailure:
            return "Unable to complete your sign-up"
        case .invalidUsername:
            return "Username already exists"
        case .noValidResponse:
            return "Couldn't get a valid response"
        case .missingData:
            return "Content not found"
        case .loggedOut:
            return "This device was remotely logged out"
        case .timeout:
            return "Connection Timeout!"
        case .offline:
            return "No internet connection"
        case .custom:
            return ""
        }
    }
}
