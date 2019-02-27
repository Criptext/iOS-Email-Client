//
//  TestSignalHandler.swift
//  iOS-Email-ClientTests
//
//  Created by Allisson on 2/25/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
@testable import iOS_Email_Client
import SignalProtocolFramework

class TestSignalHandler {
    class func decryptMessage(_ encryptedMessageB64: String, messageType: MessageType, store: AxolotlInMemoryStore, recipientId: String, deviceId: Int32) -> String{
        let sessionCipher = SessionCipher(axolotlStore: store, recipientId: recipientId, deviceId: deviceId)
        let incomingMessage : CipherMessage = messageType == .cipherText
            ? WhisperMessage.init(data: Data.init(base64Encoded: encryptedMessageB64))
            : PreKeyWhisperMessage.init(data: Data.init(base64Encoded: encryptedMessageB64))
        let plainText = sessionCipher?.decrypt(incomingMessage)
        let plainTextString = NSString(data: plainText!, encoding: String.Encoding.utf8.rawValue)
        return plainTextString! as String
    }
    
    class func buildSession(recipientId: String, deviceId: Int32, keys: [String: Any], store: AxolotlInMemoryStore){
        let contactRegistrationId = keys["registrationId"] as! Int32
        var contactPrekeyPublic: Data? = nil
        var preKeyId: Int32 = -1
        if let prekey = keys["preKey"] as? [String: Any]{
            contactPrekeyPublic = Data(base64Encoded:(prekey["publicKey"] as! String))!
            preKeyId = prekey["id"] as! Int32
        }
        
        let contactSignedPrekeyPublic: Data = Data(base64Encoded:(keys["signedPreKeyPublic"] as! String))!
        let contactSignedPrekeySignature: Data = Data(base64Encoded:(keys["signedPreKeySignature"] as! String))!
        let contactIdentityPublicKey: Data = Data(base64Encoded:(keys["identityPublicKey"] as! String))!
        let contactPreKey: PreKeyBundle = PreKeyBundle.init(registrationId: contactRegistrationId, deviceId: deviceId, preKeyId: preKeyId, preKeyPublic: contactPrekeyPublic, signedPreKeyPublic: contactSignedPrekeyPublic, signedPreKeyId: keys["signedPreKeyId"] as! Int32, signedPreKeySignature: contactSignedPrekeySignature, identityKey: contactIdentityPublicKey)
        
        let sessionBuilder: SessionBuilder = SessionBuilder.init(axolotlStore: store, recipientId: recipientId, deviceId: deviceId)
        sessionBuilder.processPrekeyBundle(contactPreKey)
    }
    
    class func encryptMessage(body: String, deviceId: Int32, recipientId: String, store: AxolotlInMemoryStore) -> (String, MessageType) {
        let sessionCipher: SessionCipher = SessionCipher.init(axolotlStore: store, recipientId: recipientId, deviceId: deviceId)
        let outgoingMessage: CipherMessage = sessionCipher.encryptMessage(body.data(using: .utf8))
        let messageText = outgoingMessage.serialized().base64EncodedString()
        let messageType = getMessageType(outgoingMessage)
        return (messageText, messageType)
    }
    
    class func decryptData(_ data: Data, messageType: MessageType, store: AxolotlInMemoryStore, recipientId: String, deviceId: Int32) -> Data? {
        let sessionCipher = SessionCipher(axolotlStore: store, recipientId: recipientId, deviceId: deviceId)
        let incomingMessage : CipherMessage = messageType == .cipherText
            ? WhisperMessage.init(data: data)
            : PreKeyWhisperMessage.init(data: data)
        return sessionCipher?.decrypt(incomingMessage)
    }
    
    class func encryptData(data: Data, deviceId: Int32, recipientId: String, store: AxolotlInMemoryStore) -> Data {
        let sessionCipher: SessionCipher = SessionCipher.init(axolotlStore: store, recipientId: String(recipientId), deviceId: deviceId)
        let outgoingMessage: CipherMessage = sessionCipher.encryptMessage(data)
        return outgoingMessage.serialized()
    }
    
    private class func getMessageType(_ message: CipherMessage) -> MessageType {
        return message is PreKeyWhisperMessage ? .preKey : .cipherText
    }
}
