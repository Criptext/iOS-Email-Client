//
//  CriptextAxolotlStore.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class CriptextAxolotlStore: NSObject{
    let sessionStore: CriptextSessionStore
    let preKeyStore: CriptextPreKeyStore
    let signedPreKeyStore: CriptextSignedPreKeyStore
    let identityKeyStore: CriptextIdentityKeyStore
    
    init(account: Account){
        identityKeyStore = CriptextIdentityKeyStore()
        sessionStore = CriptextSessionStore(account: account)
        preKeyStore = CriptextPreKeyStore(account: account)
        signedPreKeyStore = CriptextSignedPreKeyStore(account: account)
    }
    
    init(_ regId: Int32, _ base64Identity: String, account: Account){
        identityKeyStore = CriptextIdentityKeyStore(regId, base64Identity)
        sessionStore = CriptextSessionStore(account: account)
        preKeyStore = CriptextPreKeyStore(account: account)
        signedPreKeyStore = CriptextSignedPreKeyStore(account: account)
    }
}

extension CriptextAxolotlStore: AxolotlStore{
    func loadSession(_ contactIdentifier: String!, deviceId: Int32) -> SessionRecord! {
        return sessionStore.loadSession(contactIdentifier, deviceId: deviceId)
    }
    
    func subDevicesSessions(_ contactIdentifier: String!) -> [Any]! {
        return sessionStore.subDevicesSessions(contactIdentifier)
    }
    
    func storeSession(_ contactIdentifier: String!, deviceId: Int32, session: SessionRecord!) {
        return sessionStore.storeSession(contactIdentifier, deviceId: deviceId, session: session)
    }
    
    func containsSession(_ contactIdentifier: String!, deviceId: Int32) -> Bool {
        return sessionStore.containsSession(contactIdentifier, deviceId: deviceId)
    }
    
    func deleteSession(forContact contactIdentifier: String!, deviceId: Int32) {
        return sessionStore.deleteSession(forContact: contactIdentifier, deviceId: deviceId)
    }
    
    func deleteAllSessions(forContact contactIdentifier: String!) {
        return deleteAllSessions(forContact: contactIdentifier)
    }
    
    func identityKeyPair() -> ECKeyPair? {
        return identityKeyStore.identityKeyPair()
    }
    
    func localRegistrationId() -> Int32 {
        return identityKeyStore.localRegistrationId()
    }
    
    func saveRemoteIdentity(_ identityKey: Data, recipientId: String) -> Bool {
        return identityKeyStore.saveRemoteIdentity(identityKey, recipientId: recipientId)
    }
    
    func isTrustedIdentityKey(_ identityKey: Data, recipientId: String, direction: TSMessageDirection) -> Bool {
        //return identityKeyStore.isTrustedIdentityKey(identityKey, recipientId: recipientId, direction: direction)
        return true
    }
    
    func loadPreKey(_ preKeyId: Int32) -> PreKeyRecord! {
        return preKeyStore.loadPreKey(preKeyId)
    }
    
    func storePreKey(_ preKeyId: Int32, preKeyRecord record: PreKeyRecord!) {
        return preKeyStore.storePreKey(preKeyId, preKeyRecord: record)
    }
    
    func containsPreKey(_ preKeyId: Int32) -> Bool {
        return preKeyStore.containsPreKey(preKeyId)
    }
    
    func removePreKey(_ preKeyId: Int32) {
        return preKeyStore.removePreKey(preKeyId)
    }
    
    func loadSignedPrekey(_ signedPreKeyId: Int32) -> SignedPreKeyRecord {
        return signedPreKeyStore.loadSignedPrekey(signedPreKeyId)
    }
    
    func loadSignedPrekeyOrNil(_ signedPreKeyId: Int32) -> SignedPreKeyRecord? {
        return signedPreKeyStore.loadSignedPrekeyOrNil(signedPreKeyId)
    }
    
    func loadSignedPreKeys() -> [SignedPreKeyRecord] {
        return signedPreKeyStore.loadSignedPreKeys()
    }
    
    func storeSignedPreKey(_ signedPreKeyId: Int32, signedPreKeyRecord: SignedPreKeyRecord) {
        return signedPreKeyStore.storeSignedPreKey(signedPreKeyId, signedPreKeyRecord: signedPreKeyRecord)
    }
    
    func containsSignedPreKey(_ signedPreKeyId: Int32) -> Bool {
        return signedPreKeyStore.containsSignedPreKey(signedPreKeyId)
    }
    
    func removeSignedPreKey(_ signedPrekeyId: Int32) {
        return signedPreKeyStore.removeSignedPreKey(signedPrekeyId)
    }
    
    
}
