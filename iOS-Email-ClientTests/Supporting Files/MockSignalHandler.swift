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
        return """
        <p>This is a message inside paragraph tags!</p>
        <div><script>alert("I am a malicious script")</script><p>And I'm just a paragraph</p></div>
        <a href="http://www.criptext.com" onclick="execMaliciousScript()"> Link </a>
        <img src="http://www.domain.com/path/to/image.png" />
        """
    }
}
