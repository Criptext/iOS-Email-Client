//
//  CustomDomain.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/5/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class CustomDomain: Object {
    @objc dynamic var name = ""
    @objc dynamic var rowId = 0
    @objc dynamic var validated = false
    @objc dynamic var account : Account!
}
