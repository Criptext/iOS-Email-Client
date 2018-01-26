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
    dynamic var id = 0
    dynamic var email = ""
    dynamic var firstName = ""
    dynamic var lastName = ""
    dynamic var plan = ""
    dynamic var auth = ""
    dynamic var jwt = ""
    dynamic var session = ""
    dynamic var status = 0
    dynamic var monkeyId = ""
    dynamic var coupon = ""
    dynamic var pubKey = ""
    dynamic var emailHeader = ""
    dynamic var emailSignature = ""
    dynamic var defaultOn = true
    dynamic var serverAuthCode = ""
    dynamic var authentication: GIDAuthentication!
    dynamic var badge = 0
    
    dynamic var inboxNextPageToken:String? = "0"
    dynamic var inboxHistoryId:Int64 = 0
    dynamic var inboxUpdateDate:Date?
    dynamic var inboxBadge = ""
    
    dynamic var draftNextPageToken:String? = "0"
    dynamic var draftHistoryId:Int64 = 0
    dynamic var draftUpdateDate:Date?
    dynamic var draftBadge = ""
    
    dynamic var sentNextPageToken:String? = "0"
    dynamic var sentHistoryId:Int64 = 0
    dynamic var sentUpdateDate:Date?
    
    dynamic var junkNextPageToken:String? = "0"
    dynamic var junkHistoryId:Int64 = 0
    dynamic var junkUpdateDate:Date?
    
    dynamic var trashNextPageToken:String? = "0"
    dynamic var trashHistoryId:Int64 = 0
    dynamic var trashUpdateDate:Date?
    
    dynamic var allNextPageToken:String? = "0"
    dynamic var allHistoryId:Int64 = 0
    dynamic var allUpdateDate:Date?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    func nextPageToken(for label:Label) -> String? {
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
    
    func historyId(for label:Label) -> Int64 {
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
    
    func getUpdateDate(for label:Label) -> Date? {
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
