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
    var idKeyPair = Curve25519.generateKeyPair()
    var localRegId = Int32(arc4random() % 16380)
    var trustedKeys = [String: Data]()
    
    func restoreIdentity(_ base64Identity: String){
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
        if(idKeyPair?.publicKey() == identityKey){
            return true
        }
        switch(direction){
        case .incoming:
            return true
        case .outgoing:
            guard let trustedData = trustedKeys[recipientId] else {
                return false
            }
            return trustedData == identityKey
        default:
            return false
        }
    }
}
