//
//  KeysRecord.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class CRPreKeyRecord: Object{
    @objc dynamic var compoundKey = ""
    @objc dynamic var preKeyId : Int32 = 0
    @objc dynamic var preKeyPair = ""
    @objc dynamic var account : Account!
    
    func buildCompoundKey() {
        self.compoundKey = "\(account.compoundKey):\(preKeyId)"
    }
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
}
