//
//  ControllerMessage.swift
//  iOS-Email-Client
//
//  Created by Pedro on 10/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

enum ControllerMessage {
    case ReplyThread(Int)
    case LinkDevice(LinkData)
}
