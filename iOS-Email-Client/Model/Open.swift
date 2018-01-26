//
//  Open.swift
//  Criptext Secure Email
//
//  Created by Daniel Tigse on 4/7/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

class Open: Object {
    
    dynamic var timestamp: Double = 0
    dynamic var location: String = ""
    dynamic var type: Int = 1//1 open, 2 download
    
    init(fromTimestamp timestamp: Double, fromLocation location: String, fromType type: Int) {
        super.init()
        self.timestamp = timestamp
        self.location = location
        self.type = type
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init() {
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }

}
