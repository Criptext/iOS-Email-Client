//
//  Feed.swift
//  Criptext Secure Email
//
//  Created by Daniel Tigse on 4/7/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

class FeedItem: Object {
    
    @objc dynamic var id = 0
    @objc dynamic var date = Date()
    @objc dynamic var message = "" //prob not
    @objc dynamic var location = ""
    @objc dynamic var type = Action.open.rawValue
    @objc dynamic var email : Email!
    @objc dynamic var contact : Contact!
    @objc dynamic var fileId: String?
    //seen: Bool
    
    var isMuted: Bool {
        return email.isMuted
    }
    var subject: String {
        return email.subject
    }
    var formattedDate: String {
        return DateUtils.conversationTime(date).replacingOccurrences(of: "Yesterday", with: String.localize("YESTERDAY"))
    }
    var header: String {
        return "\(contact.displayName) \(type == Action.open.rawValue ? "opened" : "downloaded"):"
    }

    override static func primaryKey() -> String? {
        return "id"
    }
    
    func incrementID() -> Int {
        let realm = try! Realm()
        return (realm.objects(FeedItem.self).max(ofProperty: "id") as Int? ?? 0) + 1
    }
    
    enum Action: Int {
        case open = 1
        case download = 2
    }
}
