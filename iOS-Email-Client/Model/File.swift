//
//  File.swift
//  iOS-Email-Client
//
//  Created by Daniel Tigse on 4/4/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class File : Object {
    
    @objc dynamic var token = ""
    @objc dynamic var name = ""
    @objc dynamic var size = 0
    @objc dynamic var status = 0
    @objc dynamic var date = Date()
    @objc dynamic var readOnly = 0
    @objc dynamic var emailId = ""
    @objc dynamic var isUploaded = false
    @objc dynamic var mimeType = ""
    @objc dynamic var filePath = ""

    override static func primaryKey() -> String? {
        return "token"
    }
}
