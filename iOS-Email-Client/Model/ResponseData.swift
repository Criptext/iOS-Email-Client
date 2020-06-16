//
//  ResponseData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

enum ResponseData {
    case Error(CriptextError)
    case Success
    case SuccessAndRepeat([[String: Any]])
    case SuccessInt(Int)
    case SuccessArray([[String: Any]])
    case SuccessDictionary([String: Any])
    case SuccessString(String)
    case Unauthorized
    case Forbidden
    case Missing
    case BadRequest
    case AuthPending
    case AuthDenied
    case Conflicts
    case ConflictsInt(Int)
    case Removed
    case TooManyDevices
    case TooManyDevicesDictionary([String: Any])
    case EntityTooLarge(Int64)
    case TooManyRequests(Int64)
    case ServerError
    case PreConditionRequired(Int)
    case PreConditionFail
    case EnterpriseSuspended
}
