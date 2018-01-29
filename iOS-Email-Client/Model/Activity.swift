//
//  Activity.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/15/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Activity: Object {
    @objc dynamic var token = ""
    @objc dynamic var subject = ""
    @objc dynamic var to = ""
    @objc dynamic var toDisplayString = ""
    @objc dynamic var from = ""
    @objc dynamic var type = 0
    @objc dynamic var secondsSet = 0
    @objc dynamic var isMuted = false
    @objc dynamic var isNew = false
    @objc dynamic var exists = false
    @objc dynamic var hasOpens = false
    @objc dynamic var timestamp = 0
    @objc dynamic var recallTime = 0
    @objc dynamic var openArraySerialized = ""
    @objc dynamic var openArray = [String]()
    @objc dynamic var openArrayObjects = [Open]()
    
    override static func primaryKey() -> String? {
        return "token"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["openArray", "openArrayObjects"]
    }
}
