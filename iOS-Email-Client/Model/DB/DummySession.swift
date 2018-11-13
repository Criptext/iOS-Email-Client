//
//  DummySession.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class DummySession: Object {
    @objc dynamic var key = 0
    @objc dynamic var session = ""
    @objc dynamic var body = ""
    
    override static func primaryKey() -> String? {
        return "key"
    }
}
