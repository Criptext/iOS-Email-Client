//
//  SignalHandler.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class SignalHandler {
    class func decryptMessage(_ encryptedMessageB64: String, messageType: MessageType, account: Account, recipientId: String, deviceId: Int32) -> String{
        let axolotlStore = CriptextAxolotlStore(account.regId, account.identityB64)
        let sessionCipher = SessionCipher(axolotlStore: axolotlStore, recipientId: recipientId, deviceId: deviceId)
        let incomingMessage : CipherMessage = messageType == .cipherText
            ? WhisperMessage.init(data: Data.init(base64Encoded: encryptedMessageB64))
            : PreKeyWhisperMessage.init(data: Data.init(base64Encoded: encryptedMessageB64))
        let plainText = sessionCipher?.decrypt(incomingMessage)
        let plainTextString = NSString(data: plainText!, encoding: String.Encoding.utf8.rawValue)
        print("decrypted: \(String(describing: plainTextString))")
        return plainTextString! as String
    }
}

