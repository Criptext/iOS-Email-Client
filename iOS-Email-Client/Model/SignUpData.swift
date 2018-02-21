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
    var username: String
    var password: String
    var fullname: String
    var optionalEmail: String?
    var identifier: String{
        return username
    }
    var deviceId: Int = 1
    var preKeyId: Int32 = 0
    var signedKeyId: Int32 = 5
    var store: AxolotlInMemoryStore
    var publicKeys: [String : Any]?
    var token: String?
    
    init(_ username: String, _ password: String, _ fullname: String, optionalEmail: String?){
        self.username = username
        self.password = password
        self.fullname = fullname
        self.optionalEmail = optionalEmail
        store = AxolotlInMemoryStore()
    }
    
    func generateKeys(){
        let preKeyPair: ECKeyPair = Curve25519.generateKeyPair()
        let signedPreKeyPair: ECKeyPair = Curve25519.generateKeyPair()
        let signedPreKeySignature = Ed25519.sign(signedPreKeyPair.publicKey(), with: store.identityKeyPair())
        
        let preKey: PreKeyBundle = PreKeyBundle.init(registrationId: store.localRegistrationId(), deviceId: Int32(deviceId), preKeyId: preKeyId, preKeyPublic: preKeyPair.publicKey(), signedPreKeyPublic: signedPreKeyPair.publicKey(), signedPreKeyId: signedKeyId, signedPreKeySignature: signedPreKeySignature, identityKey: store.identityKeyPair()?.publicKey())
        
        let preKeyRecord : PreKeyRecord = PreKeyRecord.init(id: preKey.preKeyId, keyPair: preKeyPair)
        let signedPreKeyRecord: SignedPreKeyRecord = SignedPreKeyRecord.init(id: signedKeyId, keyPair: signedPreKeyPair, signature: signedPreKeySignature, generatedAt: Date())
        self.store.storePreKey(preKeyId, preKeyRecord: preKeyRecord)
        self.store.storeSignedPreKey(signedKeyId, signedPreKeyRecord: signedPreKeyRecord)
        
        
        bundleKeys(signedPreKeySignature: signedPreKeySignature!.base64EncodedString(), signedPreKeyPublic: signedPreKeyPair.publicKey().base64EncodedString(), signedPreKeyId: signedKeyId, preKeyPublicKey: preKeyPair.publicKey().base64EncodedString(), preKeyId: preKeyId, identityPublicKey: store.identityKeyPair()!.publicKey().base64EncodedString(), registrationId: store.localRegistrationId(), deviceId: Int32(deviceId), identifier: identifier)
        storeKeys(preKeyRecord, signedPreKeyRecord)
    }
    
    func storeKeys(_ preKeyRecord: PreKeyRecord, _ signedPreKeyRecord: SignedPreKeyRecord){
        let keyData = NSKeyedArchiver.archivedData(withRootObject: signedPreKeyRecord)
        let keyString = keyData.base64EncodedString()
        let signedData = NSKeyedArchiver.archivedData(withRootObject: signedPreKeyRecord)
        let signedString = signedData.base64EncodedString()
        let keysRecord = KeysRecord()
        keysRecord.preKeyId = Int(preKeyId)
        keysRecord.signedPreKeyId = Int(signedKeyId)
        keysRecord.preKeyPair = keyString
        keysRecord.signedPreKeyPair = signedString
        DBManager.store(keysRecord)
    }
    
    func bundleKeys(signedPreKeySignature: String, signedPreKeyPublic: String, signedPreKeyId: Int32, preKeyPublicKey: String, preKeyId: Int32, identityPublicKey: String, registrationId: Int32, deviceId: Int32, identifier: String){
        publicKeys = [
            "signedPreKeySignature": signedPreKeySignature,
            "signedPreKeyPublic": signedPreKeyPublic,
            "signedPreKeyId": signedPreKeyId,
            "preKeys": [[
                "publicKey": preKeyPublicKey,
                "id": preKeyId
                ]],
            "identityPublicKey": identityPublicKey,
            "registrationId": registrationId
            ] as [String : Any]
    }
}
