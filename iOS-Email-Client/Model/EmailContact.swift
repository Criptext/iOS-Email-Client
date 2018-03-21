//
//  EmailContact.swift
//  iOS-Email-Client
//
//  Created by Daniel Tigse on 3/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import RealmSwift

class EmailContact: Object{
    
    @objc dynamic var id = 0
    @objc dynamic var emailId = 0
    @objc dynamic var contactMail = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func incrementID() -> Int {
        let realm = try! Realm()
        return (realm.objects(EmailContact.self).max(ofProperty: "id") as Int? ?? 0) + 1
    }
}
