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
    case noValidResponse
    case timeout
    case offline
    case unreferencedAccount
    case custom
    case fileVersionTooOld
    
    var description: String {
        switch self {
        case .noValidResponse:
            return String.localize("NOT_VALID_RESPONSE")
        case .timeout:
            return String.localize("TIMEOUT")
        case .offline:
            return String.localize("NO_INTERNET")
        case .unreferencedAccount:
            return String.localize("UNREF_ACCOUNT")
        case .custom:
            return ""
        case .fileVersionTooOld:
            return String.localize("")
        }
    }
}
