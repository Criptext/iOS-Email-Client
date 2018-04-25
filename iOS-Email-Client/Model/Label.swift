//
//  Label.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

class Label : Object {
    @objc dynamic var id : Int = 0
    @objc dynamic var text : String = ""
    @objc dynamic var color : String = "#dddddd"
    
    init(_ labelText: String) {
        super.init()
        self.text = labelText
        self.color = Utils.generateRandomColor().toHexString()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init() {
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func incrementID() {
        let realm = try! Realm()
        id = (realm.objects(Label.self).max(ofProperty: "id") as Int? ?? 0) + 1
    }
}

enum SystemLabel: Int {
    case inbox = 1
    case draft = 6
    case sent = 3
    case spam = 2
    case trash = 7
    case starred = 5
    case important = 4
    case all = -1
    
    var id: Int {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .inbox:
            return "Inbox"
        case .draft:
            return "Draft"
        case .sent:
            return "Sent"
        case .spam:
            return "Spam"
        case .trash:
            return "Trash"
        case .important:
            return "Important"
        case .starred:
            return "Starred"
        case .all:
            return "All Mail"
        }
    }
    
    var rejectedLabelIds: [Int] {
        switch self {
        case .inbox, .sent, .all, .starred:
            return [SystemLabel.trash.id, SystemLabel.spam.id]
        case .spam:
            return [SystemLabel.trash.id]
        case .draft:
            return [SystemLabel.trash.id, SystemLabel.spam.id, SystemLabel.inbox.id, SystemLabel.sent.id, SystemLabel.trash.id]
        default:
            return []
        }
    }
    
    static var array: [SystemLabel] {
        let labels: [SystemLabel] = [.inbox, .draft, .sent, .spam, .trash, .starred, .important]
        return labels
    }
}

