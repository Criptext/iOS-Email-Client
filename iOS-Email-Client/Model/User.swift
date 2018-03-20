//
//  User.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/14/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class User: Object {
    @objc dynamic var id = 0
    @objc dynamic var email = ""
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""
    @objc dynamic var plan = ""
    @objc dynamic var auth = ""
    @objc dynamic var jwt = ""
    @objc dynamic var session = ""
    @objc dynamic var status = 0
    @objc dynamic var monkeyId = ""
    @objc dynamic var coupon = ""
    @objc dynamic var pubKey = ""
    @objc dynamic var emailHeader = ""
    @objc dynamic var emailSignature = ""
    @objc dynamic var defaultOn = true
    @objc dynamic var serverAuthCode = ""
    @objc dynamic var authentication: GIDAuthentication!
    @objc dynamic var badge = 0
    
    @objc dynamic var inboxNextPageToken:String? = "0"
    @objc dynamic var inboxHistoryId:Int64 = 0
    @objc dynamic var inboxUpdateDate:Date?
    @objc dynamic var inboxBadge = ""
    
    @objc dynamic var draftNextPageToken:String? = "0"
    @objc dynamic var draftHistoryId:Int64 = 0
    @objc dynamic var draftUpdateDate:Date?
    @objc dynamic var draftBadge = ""
    
    @objc dynamic var sentNextPageToken:String? = "0"
    @objc dynamic var sentHistoryId:Int64 = 0
    @objc dynamic var sentUpdateDate:Date?
    
    @objc dynamic var junkNextPageToken:String? = "0"
    @objc dynamic var junkHistoryId:Int64 = 0
    @objc dynamic var junkUpdateDate:Date?
    
    @objc dynamic var trashNextPageToken:String? = "0"
    @objc dynamic var trashHistoryId:Int64 = 0
    @objc dynamic var trashUpdateDate:Date?
    
    @objc dynamic var allNextPageToken:String? = "0"
    @objc dynamic var allHistoryId:Int64 = 0
    @objc dynamic var allUpdateDate:Date?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    func nextPageToken(for label:MyLabel) -> String? {
        switch label {
        case .inbox:
            return self.inboxNextPageToken
        case .draft:
            return self.draftNextPageToken
        case .sent:
            return self.sentNextPageToken
        case .junk:
            return self.junkNextPageToken
        case .trash:
            return self.trashNextPageToken
        case .all:
            return self.allNextPageToken
        default:
            return nil
        }
    }
    
    func historyId(for label:MyLabel) -> Int64 {
        switch label {
        case .inbox:
            return self.inboxHistoryId
        case .draft:
            return self.draftHistoryId
        case .sent:
            return self.sentHistoryId
        case .junk:
            return self.junkHistoryId
        case .trash:
            return self.trashHistoryId
        case .all:
            return self.allHistoryId
        default:
            return 0
        }
    }
    
    func getUpdateDate(for label:MyLabel) -> Date? {
        switch label {
        case .inbox:
            return self.inboxUpdateDate
        case .draft:
            return self.draftUpdateDate
        case .sent:
            return self.sentUpdateDate
        case .junk:
            return self.junkUpdateDate
        case .trash:
            return self.trashUpdateDate
        case .all:
            return self.allUpdateDate
        default:
            return nil
        }
    }
    
    override static func primaryKey() -> String? {
        return "email"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["authentication"]
    }
    
    func isPro() -> Bool {
        return status > 0 || status == -1
    }
    
    func statusDescription() -> String {
        switch status {
        case -1, -2:
            return "Cancelled"
        case 1:
            return "Pro"
        default:
            return "Basic"
        }
    }
}
