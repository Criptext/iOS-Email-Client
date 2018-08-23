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
    case Keys([[String: Any]])
    case PostEmail(metadata: [String: Any])
    case Success
    case Events([[String: Any]])
    case Body(String)
    case Devices([[String: Any]])
}
