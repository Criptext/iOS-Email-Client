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
    
    func buildCompoundKey() -> String {
        return "\(self.email.key):\(self.contact.email):\(self.type)"
    }
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
}

extension EmailContact{
    func toDictionary(id: Int, emailId: Int, contactId: Int) -> [String: Any] {
        return [
            "table": "email_contact",
            "object": [
                "id": id,
                "emailId": emailId,
                "contactId": contactId,
                "type": type
            ]
        ]
    }
}
