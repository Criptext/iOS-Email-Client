//
//  Bundle.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 3/6/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class CRBundle {
    let NUMBER_OF_PREKEYS = 100
    
    let account: Account
    let store: CriptextAxolotlStore
    
    var deviceId: Int = 1
    var signedKeyId: Int32 = 1
    var publicKeys: [String : Any]?
    
    var regId: Int32 {
        return store.identityKeyStore.getRegId()
    }
    
    var identity: String {
        return store.identityKeyStore.getIdentityKeyPairB64() ?? ""
    }
    
    init(account: Account) {
        self.account = account
        store = CriptextAxolotlStore(account: account)
    }
    
    @discardableResult func generateKeys() -> [String: Any] {
        let signedPreKeyPair: ECKeyPair = Curve25519.generateKeyPair()
        let signedPreKeySignature = Ed25519.sign(signedPreKeyPair.publicKey().prependByte(), with: store.identityKeyPair())
        let signedPreKeyRecord: SignedPreKeyRecord = SignedPreKeyRecord.init(id: signedKeyId, keyPair: signedPreKeyPair, signature: signedPreKeySignature, generatedAt: Date())
        store.storeSignedPreKey(signedKeyId, signedPreKeyRecord: signedPreKeyRecord)
        
        var keys = [[String: Any]]()
        for index in 1...NUMBER_OF_PREKEYS {
            let keyData = generateKey(index: Int32(index), signedPreKeyPair: signedPreKeyPair, signedPreKeySignature: signedPreKeySignature!)
            keys.append(keyData)
        }
        
        let bundle = bundleKeys(signedPreKeySignature: signedPreKeySignature!.plainBase64String(), signedPreKeyPublic: signedPreKeyPair.publicKey().customBase64String(), signedPreKeyId: signedKeyId, preKeys: keys, identityPublicKey: store.identityKeyPair()!.publicKey().customBase64String(), registrationId: store.localRegistrationId())
        publicKeys = bundle
        return bundle
    }
    
    func generateKey(index: Int32, signedPreKeyPair: ECKeyPair, signedPreKeySignature: Data) -> [String: Any] {
        let preKeyPair: ECKeyPair = Curve25519.generateKeyPair()
        let preKey: PreKeyBundle = PreKeyBundle.init(registrationId: store.localRegistrationId(), deviceId: Int32(deviceId), preKeyId: Int32(index), preKeyPublic: preKeyPair.publicKey(), signedPreKeyPublic: signedPreKeyPair.publicKey(), signedPreKeyId: signedKeyId, signedPreKeySignature: signedPreKeySignature, identityKey: store.identityKeyPair()?.publicKey())
        
        let preKeyRecord : PreKeyRecord = PreKeyRecord.init(id: preKey.preKeyId, keyPair: preKeyPair)
        
        store.storePreKey(index, preKeyRecord: preKeyRecord)
        
        return ["publicKey": preKeyPair.publicKey().customBase64String(), "id": index]
    }
    
    func generatePreKeys() -> [[String: Any]]? {
        let signedStore = CriptextSignedPreKeyStore(account: self.account)
        guard let signedRecord = signedStore.loadSignedPrekeyOrNil(signedKeyId) else {
            return nil
        }
        
        var keys = [[String: Any]]()
        for index in 1...NUMBER_OF_PREKEYS {
            let keyData = generateKey(index: Int32(index), signedPreKeyPair: signedRecord.keyPair, signedPreKeySignature: signedRecord.signature)
            keys.append(keyData)
        }
        return keys
    }
    
    func bundleKeys(signedPreKeySignature: String, signedPreKeyPublic: String, signedPreKeyId: Int32, preKeys: [[String: Any]], identityPublicKey: String, registrationId: Int32) -> [String: Any] {
        return [
            "deviceName": UIDevice.current.identifierForVendor!.uuidString,
            "deviceFriendlyName": UIDevice.current.name,
            "deviceType": Device.Kind.current.rawValue,
            "signedPreKeySignature": signedPreKeySignature,
            "signedPreKeyPublic": signedPreKeyPublic,
            "signedPreKeyId": signedPreKeyId,
            "preKeys": preKeys,
            "identityPublicKey": identityPublicKey,
            "registrationId": registrationId
            ] as [String : Any]
    }
}
