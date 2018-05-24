//
//  Device.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Device: Object {
    @objc dynamic var uuid = ""
    @objc dynamic var name = ""
    @objc dynamic var location = ""
    @objc dynamic var active = false
    @objc dynamic var mobile = false
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}
