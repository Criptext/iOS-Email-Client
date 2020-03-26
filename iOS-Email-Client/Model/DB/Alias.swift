//
//  Alias.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/5/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Alias: Object {
    @objc dynamic var name = ""
    @objc dynamic var rowId = 0
    @objc dynamic var domainName : String? = nil
    @objc dynamic var active = true
    @objc dynamic var account : Account!
    
    var email: String {
        let domain = domainName ?? Env.plainDomain
        return "\(name)@\(domain)"
    }
    
    class func aliasFromDictionary(aliasData: [String : Any], domainName: String, account: Account) -> Alias {
        let newAlias = Alias()
        newAlias.name = aliasData["name"] as! String
        newAlias.account = account
        newAlias.active = aliasData["status"] as! Bool
        newAlias.rowId = aliasData["addressId"] as! Int
        newAlias.domainName = domainName == Env.plainDomain ? nil : domainName
        return newAlias
    }
    
    override static func primaryKey() -> String? {
        return "rowId"
    }
}

extension Alias {
    func toDictionary(id: Int) -> [String: Any] {
        var obj = [
                "id": id,
                "active": active,
                "name": name,
                "rowId": rowId
            ] as [String : Any]
        if let domain = domainName {
            obj["domainName"] = domain
        }
        return [
            "table": "alias",
            "object": obj
        ]
    }
}
