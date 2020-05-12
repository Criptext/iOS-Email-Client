//
//  LinkFileHeaderData.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 7/18/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class LinkFileHeaderData {
    let fileVersion: Int
    let recipientId: String
    let domain: String
    
    var signature: String?
    var darkTheme: Bool?
    var hasCriptextFooter: Bool?
    var language: String?
    var showPreview: Bool?
    
    init(fileVersion: Int = Env.linkVersion, recipientId: String, domain: String) {
        self.fileVersion = fileVersion
        self.recipientId = recipientId
        self.domain = domain
    }
    
    func fillFromAccount(_ account: Account) {
        self.signature = account.signature
        self.hasCriptextFooter = account.showCriptextFooter
    }
    
    func toDictionary() -> [String: Any] {
        var object = [
            "fileVersion": fileVersion,
            "recipientId": recipientId,
            "domain": domain
            ] as [String : Any]
        
        if let mySignature = self.signature {
            object["signature"] = mySignature
        }
        if let myDarkTheme = self.darkTheme {
            object["darkTheme"] = myDarkTheme
        }
        if let myLanguage = self.language {
            object["language"] = myLanguage
        }
        if let myCriptextFooter = self.hasCriptextFooter {
            object["hasCriptextFooter"] = myCriptextFooter
        }
        if let myShowPreview = self.showPreview {
            object["showPreview"] = myShowPreview
        }
        
        return object
    }
}

extension LinkFileHeaderData {
    static func fromDictionary(dictionary: [String: Any]?) -> LinkFileHeaderData? {
        let fileVersionInt = dictionary?["fileVersion"] as? Int
        let fileVersionString = dictionary?["fileVersion"] as? String ?? ""
        guard let object = dictionary,
            let fileVersion = fileVersionInt ?? Int(fileVersionString),
            let recipientId = object["recipientId"] as? String,
            let domain = object["domain"] as? String else {
                return nil
        }

        var data = LinkFileHeaderData(fileVersion: fileVersion, recipientId: recipientId, domain: domain)
        
        data.signature = object["signature"] as? String
        data.darkTheme = object["darkTheme"] as? Bool
        data.language = object["language"] as? String
        data.hasCriptextFooter = object["hasCriptextFooter"] as? Bool
        data.showPreview = object["showPreview"] as? Bool
        
        return data
    }
}
