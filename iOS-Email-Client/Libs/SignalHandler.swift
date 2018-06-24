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
    
    class func buildSession(recipientId: String, deviceId: Int32, keys: [String: Any], account: Account){
        let axolotlStore = CriptextAxolotlStore(account.regId, account.identityB64)
        
        let contactRegistrationId = keys["registrationId"] as! Int32
        var contactPrekeyPublic: Data? = nil
        var preKeyId: Int32 = 0
        if let prekey = keys["preKey"] as? [String: Any]{
            contactPrekeyPublic = Data(base64Encoded:(prekey["publicKey"] as! String))!
            preKeyId = prekey["id"] as! Int32
        }
        
        let contactSignedPrekeyPublic: Data = Data(base64Encoded:(keys["signedPreKeyPublic"] as! String))!
        let contactSignedPrekeySignature: Data = Data(base64Encoded:(keys["signedPreKeySignature"] as! String))!
        let contactIdentityPublicKey: Data = Data(base64Encoded:(keys["identityPublicKey"] as! String))!
        let contactPreKey: PreKeyBundle = PreKeyBundle.init(registrationId: contactRegistrationId, deviceId: deviceId, preKeyId: preKeyId, preKeyPublic: contactPrekeyPublic, signedPreKeyPublic: contactSignedPrekeyPublic, signedPreKeyId: keys["signedPreKeyId"] as! Int32, signedPreKeySignature: contactSignedPrekeySignature, identityKey: contactIdentityPublicKey)
        
        let sessionBuilder: SessionBuilder = SessionBuilder.init(axolotlStore: axolotlStore, recipientId: recipientId, deviceId: deviceId)
        sessionBuilder.processPrekeyBundle(contactPreKey)
    }
    
    class func encryptMessage(body: String, deviceId: Int32, recipientId: String, account: Account) -> (String, MessageType) {
        let axolotlStore = CriptextAxolotlStore(account.regId, account.identityB64)
        let sessionCipher: SessionCipher = SessionCipher.init(axolotlStore: axolotlStore, recipientId: String(recipientId), deviceId: deviceId)
        let outgoingMessage: CipherMessage = sessionCipher.encryptMessage(body.data(using: .utf8))
        let messageText = outgoingMessage.serialized().base64EncodedString()
        let messageType = getMessageType(outgoingMessage)
        return (messageText, messageType)
        
    }
    
    private class func getMessageType(_ message: CipherMessage) -> MessageType {
        return message is PreKeyWhisperMessage ? .preKey : .cipherText
    }
}

