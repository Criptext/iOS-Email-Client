//
//  LabelEmail.swift
//  iOS-Email-Client
//
//  Created by Daniel Tigse on 4/4/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class LabelEmail : Object {
    
    @objc dynamic var id : Int = 0
    @objc dynamic var email_id = 0
    @objc dynamic var label_id = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func incrementID() {
        let realm = try! Realm()
        id = (realm.objects(LabelEmail.self).max(ofProperty: "id") as Int? ?? 0) + 1
    }
}
