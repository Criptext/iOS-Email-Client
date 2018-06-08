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
    
    @objc dynamic var id = 0
    @objc dynamic var date = Date()
    @objc dynamic var location = ""
    @objc dynamic var type = 1//1 open, 2 download
    @objc dynamic var emailId = ""
    @objc dynamic var contactId = ""
    @objc dynamic var fileId: String?
    @objc dynamic var newer = true

    override static func primaryKey() -> String? {
        return "id"
    }
    
    func incrementID() -> Int {
        let realm = try! Realm()
        return (realm.objects(Open.self).max(ofProperty: "id") as Int? ?? 0) + 1
    }
}
