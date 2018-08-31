//
//  ResponseData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

enum ResponseData {
    case Error(Error)
    case Success
    case SuccessInt(Int)
    case SuccessArray([[String: Any]])
    case SuccessDictionary([String: Any])
    case SuccessString(String)
    case Unauthorized
    case Forbidden
}
