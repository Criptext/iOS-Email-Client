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
    @objc dynamic var email : Email!
    @objc dynamic var contact : Contact!
    @objc dynamic var type : String = ContactType.to.rawValue
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func incrementID() {
        let realm = try! Realm()
        self.id = (realm.objects(EmailContact.self).max(ofProperty: "id") as Int? ?? 0) + 1
    }
}

extension EmailContact: CustomDictionary{
    func toDictionary() -> [String: Any] {
        return ["table": "emailContact",
                "object": [
                    "id": id,
                    "emailId": email.key,
                    "contactId": contact.id,
                    "type": type
            ]
        ]
    }
}
