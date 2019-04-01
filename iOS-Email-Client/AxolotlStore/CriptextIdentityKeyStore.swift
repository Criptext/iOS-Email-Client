//
//  CriptextIdentityKeyStore.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class CriptextIdentityKeyStore: NSObject{
    let idKeyPair : ECKeyPair
    let localRegId : Int32
    
    override init(){
        self.localRegId = Int32(arc4random() % 16380)
        self.idKeyPair = Curve25519.generateKeyPair()
    }
    
    init(_ regId: Int32, _ base64Identity: String){
        let identityData = Data(base64Encoded: base64Identity)
        let identityKeys = NSKeyedUnarchiver.unarchiveObject(with: identityData!) as! ECKeyPair
        self.idKeyPair = identityKeys
        self.localRegId = regId
    }
    
    func getIdentityKeyPairB64() -> String? {
        let identityData = NSKeyedArchiver.archivedData(withRootObject: idKeyPair)
        return identityData.base64EncodedString()
    }
    
    func getRegId() -> Int32 {
        return localRegId
    }
}

extension CriptextIdentityKeyStore: IdentityKeyStore{
    func identityKeyPair() -> ECKeyPair? {
        return idKeyPair
    }
    
    func localRegistrationId() -> Int32 {
        return localRegId
    }
    
    func saveRemoteIdentity(_ identityKey: Data, recipientId: String) -> Bool {
        let rawIdentity = identityKey.base64EncodedString()
        let trustedDevice = CRTrustedDevice()
        trustedDevice.identityB64 = rawIdentity
        trustedDevice.recipientId = recipientId
        DBAxolotl.store(trustedDevice)
        return true
    }
    
    func isTrustedIdentityKey(_ identityKey: Data, recipientId: String, direction: TSMessageDirection) -> Bool {
        if(idKeyPair.publicKey() == identityKey || direction == .incoming){
            return true
        }
        
        guard direction == .outgoing,
            let trustedDevice = DBAxolotl.getTrustedDevice(recipientId: recipientId) else {
            return true
        }
        
        guard let trustedData = Data(base64Encoded: trustedDevice.identityB64) else {
            return false
        }
        
        return trustedData == identityKey
    }
}
