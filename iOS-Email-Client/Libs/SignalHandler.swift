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
    class func decryptMessage(_ encryptedMessageB64: String, account: Account) -> String{
        let axolotlStore = CriptextAxolotlStore(account.regId, account.identityB64)
        let sessionCipher = SessionCipher(axolotlStore: axolotlStore, recipientId: account.username, deviceId: 1)
        let incomingMessage = PreKeyWhisperMessage.init(data: Data.init(base64Encoded: encryptedMessageB64))
        let plainText = sessionCipher?.decrypt(incomingMessage)
        let plainTextString = NSString(data:plainText!, encoding:String.Encoding.ascii.rawValue)
        print("decrypted: \(String(describing: plainTextString))")
        return plainTextString! as String
    }
}
