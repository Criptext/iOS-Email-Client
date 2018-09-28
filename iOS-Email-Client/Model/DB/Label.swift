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
    @objc dynamic var color : String = "dddddd"
    @objc dynamic var type : String = "custom"
    @objc dynamic var visible : Bool = true
    
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
    
    class func getMoveableLabels(label: Int) -> [Label] {
        let moveableLabels = (SystemLabel.init(rawValue: label) ?? .starred).moveableLabels
        return moveableLabels.map({ (label) -> Label in
            return DBManager.getLabel(label.id)!
        })
    }
    
    class func getSettableLabels() -> [Label] {
        var settableLabels = DBManager.getActiveCustomLabels()
        settableLabels.append(DBManager.getLabel(SystemLabel.starred.id)!)
        return settableLabels
    }
}

extension Label {
    func toDictionary() -> [String: Any] {
        return [
            "table": "label",
            "object": [
                "id": id,
                "color": color,
                "text": text,
                "type": type,
                "visible": visible
            ]
        ]
    }
}

enum SystemLabel: Int {
    case inbox = 1
    case draft = 6
    case sent = 3
    case spam = 2
    case trash = 7
    case starred = 5
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
        case .starred:
            return "Starred"
        case .all:
            return "All Mail"
        }
    }
    
    var hexColor: String {
        switch self {
        case .inbox:
            return "0091ff"
        case .draft:
            return "666666"
        case .sent:
            return "1a9759"
        case .spam:
            return "ff0000"
        case .trash:
            return "b00e0e"
        case .starred:
            return "ffdf32"
        case .all:
            return "000000"
        }
    }
    
    var moveableLabels: [SystemLabel] {
        switch self {
        case .inbox, .sent, .starred:
            return [.trash, .spam]
        case .draft, .spam:
            return []
        case .trash:
            return [.spam]
        case .all:
            return [.inbox, .spam, .trash]
        }
    }
    
    var rejectedLabelIds: [Int] {
        switch self {
        case .spam, .trash, .draft:
            return []
        default:
            return [SystemLabel.trash.id, SystemLabel.spam.id]
        }
    }
    
    static func fromText(text: String) -> Int {
        switch text {
        case SystemLabel.inbox.description:
            return SystemLabel.inbox.id
        case SystemLabel.draft.description:
            return SystemLabel.draft.id
        case SystemLabel.sent.description:
            return SystemLabel.sent.id
        case SystemLabel.spam.description:
            return SystemLabel.spam.id
        case SystemLabel.trash.description:
            return SystemLabel.trash.id
        case SystemLabel.starred.description:
            return SystemLabel.starred.id
        default:
            return SystemLabel.all.id
        }
    }
    
    static var array: [SystemLabel] {
        let labels: [SystemLabel] = [.inbox, .draft, .sent, .spam, .trash, .starred]
        return labels
    }
    
    static var idsArray: [Int] {
        let labels: [Int] = [SystemLabel.inbox.id, SystemLabel.draft.id, SystemLabel.sent.id, SystemLabel.spam.id, SystemLabel.trash.id, SystemLabel.starred.id]
        return labels
    }
}

