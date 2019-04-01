//
//  TrustedDevice.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class CRTrustedDevice: Object{
    @objc dynamic var recipientId = ""
    @objc dynamic var identityB64 = ""
    @objc dynamic var account : Account!
    
    override static func primaryKey() -> String? {
        return "recipientId"
    }
}
