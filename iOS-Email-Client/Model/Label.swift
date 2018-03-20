//
//  Label.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Label : Object {
    @objc dynamic var id : Int = 0
    @objc dynamic var text : String = ""
    @objc dynamic var color : String = "#dddddd"
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
