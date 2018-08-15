//
//  Dummy.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/27/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class Dummy {

    let store = AxolotlInMemoryStore()
    let deviceId : Int32 = 1
    let preKeyId : Int32 = 1
    let signedKeyId : Int32 = 1
    let preKeyPair: ECKeyPair
    let signedPreKeyPair: ECKeyPair
    let signedPreKeySignature: Data
    let recipientId: String
    
    init(recipientId: String){
        self.recipientId = recipientId
        preKeyPair = Curve25519.generateKeyPair()
        signedPreKeyPair = Curve25519.generateKeyPair()
        signedPreKeySignature = Ed25519.sign(signedPreKeyPair.publicKey().prependByte(), with: store.identityKeyPair())
        
        let preKey: PreKeyBundle = PreKeyBundle.init(registrationId: store.localRegistrationId(), deviceId: deviceId, preKeyId: preKeyId, preKeyPublic: preKeyPair.publicKey(), signedPreKeyPublic: signedPreKeyPair.publicKey(), signedPreKeyId: signedKeyId, signedPreKeySignature: signedPreKeySignature, identityKey: store.identityKeyPair()?.publicKey())
        
        self.store.storePreKey(preKeyId, preKeyRecord: PreKeyRecord.init(id: preKey.preKeyId, keyPair: preKeyPair))
        self.store.storeSignedPreKey(signedKeyId, signedPreKeyRecord: SignedPreKeyRecord.init(id: signedKeyId, keyPair: preKeyPair, signature: signedPreKeySignature, generatedAt: Date()))
    }
    
    func getKeyBundle() -> [String: Any]{
        return [
            "signedPreKeySignature": signedPreKeySignature.plainBase64String(),
            "signedPreKeyPublic": signedPreKeyPair.publicKey().customBase64String(),
            "signedPreKeyId": signedKeyId,
            "preKey": [
                "publicKey": preKeyPair.publicKey().customBase64String(),
                "id": preKeyId
                ],
            "identityPublicKey": store.identityKeyPair()!.publicKey().customBase64String(),
            "registrationId": store.localRegistrationId(),
            "deviceId": deviceId,
            "recipientId": recipientId
            ] as [String : Any]
    }
    
    func getSessionBundle() -> [String: Any]{
        let identityKeyPair = store.identityKeyPair()!
        return [
            "registrationId": store.localRegistrationId(),
            "identityKey": [
                "publicKey": identityKeyPair.publicKey().customBase64String(),
                "privateKey": identityKeyPair.privateKey().plainBase64String()
            ],
            "preKey": [
                "keyId": preKeyId,
                "publicKey": preKeyPair.publicKey().customBase64String(),
                "privateKey": preKeyPair.privateKey().plainBase64String()
            ],
            "signedPreKey": [
                "keyId": signedKeyId,
                "publicKey": signedPreKeyPair.publicKey().customBase64String(),
                "privateKey": signedPreKeyPair.privateKey().plainBase64String()
            ]
            ] as [String : Any]
    }
    
}
