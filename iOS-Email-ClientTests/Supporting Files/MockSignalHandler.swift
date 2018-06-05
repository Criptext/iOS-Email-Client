//
//  MockSignalHandler.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 6/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
@testable import iOS_Email_Client

class MockSignalHandler: SignalHandler {
    override class func decryptMessage(_ encryptedMessageB64: String, messageType: MessageType, account: Account, recipientId: String, deviceId: Int32) -> String{
        return "<p>This is a message inside paragraph tags!</p>"
    }
}
