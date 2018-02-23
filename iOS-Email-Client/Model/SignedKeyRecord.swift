//
//  SignedPreKeyRecord.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/26/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class SignedKeyRecord: Object{
    @objc dynamic var signedPreKeyId = 0
    @objc dynamic var signedPreKeyPair = ""
    
    override static func primaryKey() -> String? {
        return "signedPreKeyId"
    }
}
