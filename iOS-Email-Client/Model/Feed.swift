//
//  Feed.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Feed: Object{
    @objc dynamic var token = ""
    @objc dynamic var message = ""
    @objc dynamic var subject = ""
    @objc dynamic var timestamp = 0
    @objc dynamic var isNew = false
    @objc dynamic var isOpen = false
    @objc dynamic var isMuted = false
    
    func getFormattedDate() -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp))
        return DateUtils.conversationTime(date)
    }
    
    override static func primaryKey() -> String? {
        return "token"
    }
}
