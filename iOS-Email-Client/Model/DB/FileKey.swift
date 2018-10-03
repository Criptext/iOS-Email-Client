//
//  FileKey.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/17/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class FileKey : Object {
    @objc dynamic var id = 0
    @objc dynamic var key = ""
    @objc dynamic var emailId = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func incrementID() {
        let realm = try! Realm()
        id = (realm.objects(FileKey.self).max(ofProperty: "id") as Int? ?? 0) + 1
    }
    
    func getKeyAndIv() -> (Data, Data){
        let keys = key.split(separator: ":")
        return (Data(base64Encoded: String(keys[0]), options: .ignoreUnknownCharacters)!, Data(base64Encoded: String(keys[1]), options: .ignoreUnknownCharacters)!)
    }
    
    class func getKeyCodedString(key: Data, iv: Data) -> String{
        return "\(key.base64EncodedString()):\(iv.base64EncodedString())"
    }
}

extension FileKey  {
    func toDictionary(emailId: Int) -> [String: Any] {
        return [
            "table": "file_key",
            "object": [
                "id": id,
                "key": String(key.split(separator: ":").first!),
                "iv": String(key.split(separator: ":").last!),
                "emailId": emailId
            ]
        ]
    }
}
