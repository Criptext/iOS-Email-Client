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
    var indentityStore = CriptextIdentityKeyStore()
    var keyStore = CriptextPreKeyStore()
    var signedKeyStore = CriptextSignedPreKeyStore()
    var publicKeys: [String : Any]?
    var token: String?
    
    init(_ username: String, _ password: String, _ fullname: String, optionalEmail: String?){
        self.username = username
        self.password = password
        self.fullname = fullname
        self.optionalEmail = optionalEmail
    }
    
    func generateKeys(){
        let preKeyPair: ECKeyPair = Curve25519.generateKeyPair()
        let signedPreKeyPair: ECKeyPair = Curve25519.generateKeyPair()
        let signedPreKeySignature = Ed25519.sign(signedPreKeyPair.publicKey(), with: indentityStore.identityKeyPair())
        
        let preKey: PreKeyBundle = PreKeyBundle.init(registrationId: indentityStore.localRegistrationId(), deviceId: Int32(deviceId), preKeyId: preKeyId, preKeyPublic: preKeyPair.publicKey(), signedPreKeyPublic: signedPreKeyPair.publicKey(), signedPreKeyId: signedKeyId, signedPreKeySignature: signedPreKeySignature, identityKey: indentityStore.identityKeyPair()?.publicKey())
        
        let preKeyRecord : PreKeyRecord = PreKeyRecord.init(id: preKey.preKeyId, keyPair: preKeyPair)
        let signedPreKeyRecord: SignedPreKeyRecord = SignedPreKeyRecord.init(id: signedKeyId, keyPair: signedPreKeyPair, signature: signedPreKeySignature, generatedAt: Date())
        keyStore.storePreKey(preKeyId, preKeyRecord: preKeyRecord)
        signedKeyStore.storeSignedPreKey(signedKeyId, signedPreKeyRecord: signedPreKeyRecord)
        
        bundleKeys(signedPreKeySignature: signedPreKeySignature!.base64EncodedString(), signedPreKeyPublic: signedPreKeyPair.publicKey().base64EncodedString(), signedPreKeyId: signedKeyId, preKeyPublicKey: preKeyPair.publicKey().base64EncodedString(), preKeyId: preKeyId, identityPublicKey: indentityStore.identityKeyPair()!.publicKey().base64EncodedString(), registrationId: indentityStore.localRegistrationId(), deviceId: Int32(deviceId), identifier: identifier)
        
        let defaults = UserDefaults.standard
        let myIdentity = indentityStore.identityKeyPair()
        let identityData = NSKeyedArchiver.archivedData(withRootObject: myIdentity!)
        let identityString = identityData.base64EncodedString()
        defaults.set(identityString, forKey: "identity")
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
