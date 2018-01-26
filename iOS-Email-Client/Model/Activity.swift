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
    dynamic var token = ""
    dynamic var subject = ""
    dynamic var to = ""
    dynamic var toDisplayString = ""
    dynamic var from = ""
    dynamic var type = 0
    dynamic var secondsSet = 0
    dynamic var isMuted = false
    dynamic var isNew = false
    dynamic var exists = false
    dynamic var hasOpens = false
    dynamic var timestamp = 0
    dynamic var recallTime = 0
    dynamic var openArraySerialized = ""
    dynamic var openArray = [String]()
    dynamic var openArrayObjects = [Open]()
    
    override static func primaryKey() -> String? {
        return "token"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["openArray", "openArrayObjects"]
    }
}
