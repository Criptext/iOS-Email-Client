//
//  Contact.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 5/18/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import RealmSwift
import Foundation

class Contact: Object {
    @objc dynamic var displayName = "" //name
    @objc dynamic var email = ""
    @objc dynamic var isTrusted = false
    @objc dynamic var score = 0
    
    let accountContacts = LinkingObjects(fromType: AccountContact.self, property: "contact")
    
    override static func primaryKey() -> String? {
        return "email"
    }
}

extension Contact {
    func toDictionary(id: Int) -> [String: Any] {
        return [
            "table": "contact",
            "object": [
                "id": id,
                "email": email,
                "name": displayName,
                "isTrusted": isTrusted
            ]
        ]
    }
}

func ==(lhs: Contact, rhs: Contact) -> Bool {
    return lhs.email == rhs.email
}
