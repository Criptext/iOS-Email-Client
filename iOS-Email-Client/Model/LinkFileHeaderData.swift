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
    
    init(fileVersion: Int = Env.linkVersion, recipientId: String, domain: String) {
        self.fileVersion = fileVersion
        self.recipientId = recipientId
        self.domain = domain
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "fileVersion": fileVersion,
            "recipientId": recipientId,
            "domain": domain
        ]
    }
}

extension LinkFileHeaderData {
    static func fromDictionary(dictionary: [String: Any]?) -> LinkFileHeaderData? {
        if(dictionary == nil) { return nil }
        guard let fileVersion = dictionary?["fileVersion"] as? Int,
            let recipientId = dictionary?["recipientId"] as? String,
            let domain = dictionary?["domain"] as? String else {
                return nil
        }

        return LinkFileHeaderData(fileVersion: fileVersion, recipientId: recipientId, domain: domain)
    }
}
