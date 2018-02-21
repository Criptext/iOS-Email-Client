//
//  KeysRecord.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class KeysRecord: Object{
    @objc dynamic var preKeyId = 0
    @objc dynamic var signedPreKeyId = 0
    @objc dynamic var preKeyPair = ""
    @objc dynamic var signedPreKeyPair = ""
    
    override static func primaryKey() -> String? {
        return "preKeyId"
    }
}
