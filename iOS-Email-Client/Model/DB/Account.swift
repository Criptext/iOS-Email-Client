//
//  Account.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Account: Object{
    @objc dynamic var compoundKey = ""
    @objc dynamic var username = ""
    @objc dynamic var deviceId = 1
    @objc dynamic var name = ""
    @objc dynamic var jwt = ""
    @objc dynamic var refreshToken: String? = nil
    @objc dynamic var identityB64 = ""
    @objc dynamic var regId : Int32 = 0
    @objc dynamic var signature = ""
    @objc dynamic var signatureEnabled = false
    @objc dynamic var lastTimeFeedOpened = Date()
    @objc dynamic var domain: String? = nil
    @objc dynamic var isActive = false
    @objc dynamic var isLoggedIn = false
    
    @objc dynamic var hasCloudBackup = false
    @objc dynamic var lastTimeBackup: Date? = nil
    @objc dynamic var autoBackupFrequency = "Off"
    @objc dynamic var wifiOnly = true
    
    var email: String {
        guard let myDomain = domain else {
            return "\(username)\(Constants.domain)"
        }
        return "\(username)@\(myDomain)"
    }
    
    func buildCompoundKey() {
        self.compoundKey = "\(username)\(domain ?? "")"
    }
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
}
