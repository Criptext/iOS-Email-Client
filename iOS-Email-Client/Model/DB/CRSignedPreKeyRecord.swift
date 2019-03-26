//
//  SignedPreKeyRecord.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/26/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class CRSignedPreKeyRecord: Object{
    @objc dynamic var compoundKey = ""
    @objc dynamic var signedPreKeyId : Int32 = 0
    @objc dynamic var signedPreKeyPair = ""
    @objc dynamic var account : Account!
    
    func buildCompoundKey() {
        self.compoundKey = "\(account.compoundKey):\(signedPreKeyId)"
    }
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
}
