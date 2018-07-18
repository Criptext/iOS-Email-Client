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
        return (keys[0].data(using: .utf8)!, keys[1].data(using: .utf8)!)
    }
}
