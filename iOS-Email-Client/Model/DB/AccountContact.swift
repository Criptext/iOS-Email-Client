//
//  AccountContact.swift
//  iOS-Email-Client
//
//  Created by Allisson on 3/6/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class AccountContact: Object{
    
    @objc dynamic var compoundKey = ""
    @objc dynamic var account : Account!
    @objc dynamic var contact : Contact!
    
    func buildCompoundKey() {
        self.compoundKey = "\(self.account.compoundKey):\(self.contact.email)"
    }
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
}
