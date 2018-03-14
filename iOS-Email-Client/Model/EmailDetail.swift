//
//  EmailDetail.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class EmailDetail: Object {
    @objc dynamic var key = ""
    @objc dynamic var threadId = ""
    @objc dynamic var s3Key = ""
    @objc dynamic var unread = true
    @objc dynamic var secure = true
    @objc dynamic var content = ""
    @objc dynamic var preview = ""
    @objc dynamic var subject = ""
    @objc dynamic var delivered = ""
    @objc dynamic var date : Date?
    @objc dynamic var isTrash = false
    @objc dynamic var isDraft = false
    var myHeight : CGFloat = 0.0
    var isExpanded = false
    
    override static func primaryKey() -> String? {
        return "key"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["myHeight", "isExpanded"]
    }
}
