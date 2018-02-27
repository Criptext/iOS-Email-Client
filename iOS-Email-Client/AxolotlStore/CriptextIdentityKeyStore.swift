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
    let localRegId = Int32(arc4random() % 16380)
    let trustedKeys = [String: Data]()
    
    override init(){
        self.idKeyPair = Curve25519.generateKeyPair()
    }
    
    init(_ base64Identity: String){
        let identityData = Data(base64Encoded: base64Identity)
        let identityKeys = NSKeyedUnarchiver.unarchiveObject(with: identityData!) as! ECKeyPair
        self.idKeyPair = identityKeys
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
        return trustedKeys[recipientId] == identityKey
    }
    
    func isTrustedIdentityKey(_ identityKey: Data, recipientId: String, direction: TSMessageDirection) -> Bool {
        if(idKeyPair.publicKey() == identityKey || direction == .incoming){
            return true
        }
        guard direction == .outgoing,
            let trustedData = trustedKeys[recipientId] else {
            return false
        }
        return trustedData == identityKey
    }
}
