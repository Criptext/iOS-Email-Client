//
//  EmailContact.swift
//  iOS-Email-Client
//
//  Created by Daniel Tigse on 3/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import RealmSwift

class EmailContact: Object{
    
    @objc dynamic var compoundKey = ""
    @objc dynamic var email : Email!
    @objc dynamic var contact : Contact!
    @objc dynamic var type : String = ContactType.to.rawValue
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
}

extension EmailContact: CustomDictionary{
    func toDictionary() -> [String: Any] {
        return ["table": "emailContact",
                "object": [
                    "emailId": email.key,
                    "contactId": contact.id,
                    "type": type
            ]
        ]
    }
}
