//
//  QueueItem.swift
//  iOS-Email-Client
//
//  Created by Pedro on 10/24/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class QueueItem: Object {
    @objc dynamic var date = Date()
    @objc dynamic var timestamp: String = Date().timeIntervalSince1970.description
    @objc dynamic var serializedParams = ""
    @objc dynamic var account : Account!
    
    var params: [String: Any] {
        set(dic) {
            guard let jsonString = Utils.convertToJSONString(dictionary: dic) else {
                return
            }
            serializedParams = jsonString
        }
        get {
            guard let params = Utils.convertToDictionary(text: serializedParams) else {
                return [String: Any]()
            }
            return params
        }
    }
    
    override static func primaryKey() -> String? {
        return "timestamp"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["params"]
    }
}
