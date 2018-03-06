//
//  KeysRecord.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class KeyRecord: Object{
    @objc dynamic var preKeyId : Int32 = 0
    @objc dynamic var preKeyPair = ""
    
    override static func primaryKey() -> String? {
        return "preKeyId"
    }
}
