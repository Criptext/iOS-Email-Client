//
//  LoginParams.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/27/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class LoginParams {
    let username: String
    let domain: String
    let password: String
    var jwt: String
    var isTwoFactor = false
    var needToRemoveDevices: Bool = false
    let name: String
    let deviceId: Int
    let blockRemoteContent: Bool
    let customerType: Int
    var maxDevices = 0
    let addresses: [[String: Any]]?
    
    var email: String {
        return "\(username)@\(domain)"
    }
    
    init(username: String, domain: String, password: String, data: [String: Any]){
        self.username = username
        self.domain = domain
        self.password = password
        
        isTwoFactor = (data["twoFactorAuth"] as? Int ?? 0) == 0 ? false : true
        needToRemoveDevices = (data["hasTooManyDevices"] as! Int) == 0 ? false : true
        
        blockRemoteContent = (data["blockRemoteContent"] as! Int) == 0 ? false : true
        customerType = data["customerType"] as! Int
        name = data["name"] as! String
        deviceId = data["deviceId"] as! Int
        jwt = data["token"] as! String
        addresses = data["addresses"] as? [[String: Any]]
    }
    
    func createAccount() -> Account {
        let myAccount = Account()
        myAccount.username = username
        myAccount.domain = domain == Env.plainDomain ? nil : domain
        myAccount.name = name
        myAccount.jwt = jwt
        myAccount.refreshToken = nil
        myAccount.regId = 0
        myAccount.identityB64 = ""
        myAccount.deviceId = deviceId
        myAccount.buildCompoundKey()
        myAccount.customerType = customerType
        return myAccount
    }
    
    class func parseAddresses(addresses: [[String: Any]], account: Account) {
        let (aliasesPairArray) = addresses.map({aliasesDomainFromDictionary(data: $0, account: account)})
        for pair in aliasesPairArray {
            if pair.0.name != Env.plainDomain {
                DBManager.store(pair.0)
            }
            DBManager.store(aliases: pair.1)
            if let defaultAddressId = pair.2 {
                DBManager.update(account: account, defaultAddressId: defaultAddressId)
            }
        }
    }
    
    class func aliasesDomainFromDictionary(data: [String: Any], account: Account) -> (CustomDomain, [Alias], Int?) {
        let aliases = data["aliases"] as! [[String: Any]]
        let domainData = data["domain"] as! [String: Any]
        let domainName = domainData["name"] as! String
        let domainVerified = domainData["confirmed"] as! Int
        
        let domain = CustomDomain()
        domain.name = domainName
        domain.validated = domainVerified == 1 ? true : false
        domain.account = account
        
        var defaultAddressId: Int? = nil
        let aliasesArray: [Alias] = aliases.map { aliasObj in
            let alias = Alias.aliasFromDictionary(aliasData: aliasObj, domainName: domainName, account: account)
            if let isDefault = aliasObj["default"] as? Int,
                isDefault == 1 {
                defaultAddressId = alias.rowId
            }
            return alias
        }
        
        return (domain, aliasesArray, defaultAddressId)
    }
}
