//
//  Contact.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 5/18/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import RealmSwift

class Contact: Object {
    @objc dynamic var id = 0
    @objc dynamic var displayName = "" //name
    @objc dynamic var email = ""
    
    override static func primaryKey() -> String? {
        return "email"
    }
}

extension Contact: CustomDictionary {
    func toDictionary() -> [String: Any] {
        return [
            "table": "contact",
            "object": [
                "id": id,
                "email": email,
                "name": displayName
            ]
        ]
    }
}

func ==(lhs: Contact, rhs: Contact) -> Bool {
    return lhs.email == rhs.email
}
