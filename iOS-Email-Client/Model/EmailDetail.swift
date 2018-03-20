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
    @objc dynamic var delivered = DeliveryStatus.SENT
    @objc dynamic var date : Date?
    @objc dynamic var isTrash = false
    @objc dynamic var isDraft = false
    var isExpanded = false
    
    override static func primaryKey() -> String? {
        return "key"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["isExpanded"]
    }
    
    var isUnsent: Bool{
        return delivered == DeliveryStatus.UNSENT
    }
}

struct DeliveryStatus {
    static let PENDING = 0
    static let SENT = 1
    static let DELIVERED = 2
    static let UNSENT = -1
}
