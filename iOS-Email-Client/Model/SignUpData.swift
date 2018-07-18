//
//  SignUpData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class SignUpData{
    let NUMBER_OF_PREKEYS = 100
    var username: String
    var password: String
    var fullname: String
    var optionalEmail: String?
    var identifier: String{
        return username
    }
    var deviceId: Int = 1
    var signedKeyId: Int32 = 1
    var store = CriptextAxolotlStore()
    var publicKeys: [String : Any]?
    var token: String?
    
    init(username: String, password: String, fullname: String, optionalEmail: String?){
        self.username = username
        self.password = password
        self.fullname = fullname
        self.optionalEmail = optionalEmail
    }
    
    func generateKeys(){
        let signedPreKeyPair: ECKeyPair = Curve25519.generateKeyPair()
        let signedPreKeySignature = Ed25519.sign(signedPreKeyPair.publicKey().prependByte(), with: store.identityKeyPair())
        let signedPreKeyRecord: SignedPreKeyRecord = SignedPreKeyRecord.init(id: signedKeyId, keyPair: signedPreKeyPair, signature: signedPreKeySignature, generatedAt: Date())
        store.storeSignedPreKey(signedKeyId, signedPreKeyRecord: signedPreKeyRecord)
        
        var keys = [[String: Any]]()
        for index in 1...NUMBER_OF_PREKEYS {
            let keyData = generateKey(index: Int32(index), signedPreKeyPair: signedPreKeyPair, signedPreKeySignature: signedPreKeySignature!)
            keys.append(keyData)
        }
        
        bundleKeys(signedPreKeySignature: signedPreKeySignature!.plainBase64String(), signedPreKeyPublic: signedPreKeyPair.publicKey().customBase64String(), signedPreKeyId: signedKeyId, preKeys: keys, identityPublicKey: store.identityKeyPair()!.publicKey().customBase64String(), registrationId: store.localRegistrationId())
    }
    
    func generateKey(index: Int32, signedPreKeyPair: ECKeyPair, signedPreKeySignature: Data) -> [String: Any] {
        let preKeyPair: ECKeyPair = Curve25519.generateKeyPair()
        let preKey: PreKeyBundle = PreKeyBundle.init(registrationId: store.localRegistrationId(), deviceId: Int32(deviceId), preKeyId: Int32(index), preKeyPublic: preKeyPair.publicKey(), signedPreKeyPublic: signedPreKeyPair.publicKey(), signedPreKeyId: signedKeyId, signedPreKeySignature: signedPreKeySignature, identityKey: store.identityKeyPair()?.publicKey())
        
        let preKeyRecord : PreKeyRecord = PreKeyRecord.init(id: preKey.preKeyId, keyPair: preKeyPair)
        
        store.storePreKey(index, preKeyRecord: preKeyRecord)
        
        return ["publicKey": preKeyPair.publicKey().customBase64String(), "id": index]
    }
    
    func bundleKeys(signedPreKeySignature: String, signedPreKeyPublic: String, signedPreKeyId: Int32, preKeys: [[String: Any]], identityPublicKey: String, registrationId: Int32){
        publicKeys = [
            "deviceName": UIDevice.current.identifierForVendor!.uuidString,
            "deviceFriendlyName": UIDevice.current.identifierForVendor!.uuidString,
            "deviceType": Device.Kind.current.rawValue,
            "signedPreKeySignature": signedPreKeySignature,
            "signedPreKeyPublic": signedPreKeyPublic,
            "signedPreKeyId": signedPreKeyId,
            "preKeys": preKeys,
            "identityPublicKey": identityPublicKey,
            "registrationId": registrationId
            ] as [String : Any]
    }
    
    func buildDataForRequest() -> [String : Any]{
        if(publicKeys == nil){
            generateKeys()
        }
        var data = [
            "recipientId": username,
            "password": password,
            "name": fullname,
            "keybundle": publicKeys!
            ] as [String : Any]
        if(optionalEmail != nil && !optionalEmail!.isEmpty){
            data["recoveryEmail"] = optionalEmail
        }
        
        return data
    }
    
    func getIdentityKeyPairB64() -> String? {
        guard let myIdentity = store.identityKeyPair() else {
            return nil
        }
        let identityData = NSKeyedArchiver.archivedData(withRootObject: myIdentity)
        return identityData.base64EncodedString()
    }
    
    func getRegId() -> Int32 {
        return store.localRegistrationId()
    }
}
