//
//  Contact.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 5/18/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import RealmSwift

class Contact: Object {
    @objc dynamic var displayName = ""
    @objc dynamic var email = ""
    
    override static func primaryKey() -> String? {
        return "email"
    }
}

func ==(lhs: Contact, rhs: Contact) -> Bool {
    return lhs.email == rhs.email
}
