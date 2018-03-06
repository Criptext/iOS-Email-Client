//
//  DBManager.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/16/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftyJSON
import RealmSwift

//MARK: - User related
class DBManager {
    class func getReference(_ obj:Object) -> ThreadSafeReference<Object> {
        return ThreadSafeReference(to: obj)
    }
    
    class func getObject(_ ref:ThreadSafeReference<Object>) -> Object? {
        let realm = try! Realm()
        
        return realm.resolve(ref)
    }
    
    class func signout(){
        let realm = try! Realm()
        
        try! realm.write {
            realm.deleteAll()
        }
    }
    class func store(_ user:User){
        let realm = try! Realm()
        
        try! realm.write() {
            realm.add(user, update: true)
        }
    }
    
    class func update(_ user:User, coupon:String){
        let realm = try! Realm()
        
        try! realm.write() {
            user.coupon = coupon
        }
    }
    
    class func update(_ user:User, signature:String){
        let realm = try! Realm()
        
        try! realm.write() {
            user.emailSignature = signature
        }
    }
    
    class func update(_ user:User, header:String){
        let realm = try! Realm()
        
        try! realm.write() {
            user.emailHeader = header
        }
    }
    
    class func update(_ user:User, status:Int){
        let realm = try! Realm()
        
        try! realm.write() {
            user.status = status
        }
    }
    
    class func update(_ user:User, plan:String){
        let realm = try! Realm()
        
        try! realm.write() {
            user.plan = plan
        }
    }
    
    class func update(_ user:User, jwt:String){
        let realm = try! Realm()
        
        try! realm.write() {
            user.jwt = jwt
        }
    }
    
    class func update(_ user:User, session:String){
        let realm = try! Realm()
        
        try! realm.write() {
            user.session = session
        }
    }
    
    class func update(_ user:User, switchValue:Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            user.defaultOn = switchValue
        }
    }
    
    class func update(_ user:User, badge:Int){
        let realm = try! Realm()
        
        try! realm.write() {
            if(badge < 0){
                user.badge = 0
            }
            else{
                user.badge = badge
            }
        }
    }
 
    class func update(_ user:User, badge:NSNumber, label:Label){
        let realm = try! Realm()
        
        let badgeString = String(describing: badge)
        try! realm.write() {
            
            if label == .inbox {
                user.inboxBadge = badgeString != "0" ? badgeString : ""
            }
            
            if label == .draft {
                user.draftBadge = badgeString != "0" ? badgeString : ""
            }
        }
    }
    
    class func update(_ user:User, historyId:Int64, label:Label){
        let realm = try! Realm()
        
        try! realm.write() {
            switch label {
            case .inbox:
                user.inboxHistoryId = historyId
                break
            case .draft:
                user.draftHistoryId = historyId
                break
            case .sent:
                user.sentHistoryId = historyId
                break
            case .junk:
                user.junkHistoryId = historyId
                break
            case .trash:
                user.trashHistoryId = historyId
                break
            case .all:
                user.allHistoryId = historyId
                break
            default:
                break
            }
            
        }
    }
    
    class func update(_ user:User, nextPageToken:String?, label:Label){
        let realm = try! Realm()
        
        try! realm.write() {
            switch label {
            case .inbox:
                user.inboxNextPageToken = nextPageToken
                break
            case .draft:
                user.draftNextPageToken = nextPageToken
                break
            case .sent:
                user.sentNextPageToken = nextPageToken
                break
            case .junk:
                user.junkNextPageToken = nextPageToken
                break
            case .trash:
                user.trashNextPageToken = nextPageToken
                break
            case .all:
                user.allNextPageToken = nextPageToken
                break
            default:
                break
            }
            
        }
    }
    
    class func update(_ user:User, updateDate:Date?, label:Label){
        let realm = try! Realm()
        
        try! realm.write() {
            switch label {
            case .inbox:
                user.inboxUpdateDate = updateDate
                break
            case .draft:
                user.draftUpdateDate = updateDate
                break
            case .sent:
                user.sentUpdateDate = updateDate
                break
            case .junk:
                user.junkUpdateDate = updateDate
                break
            case .trash:
                user.trashUpdateDate = updateDate
                break
            case .all:
                user.allUpdateDate = updateDate
                break
            default:
                break
            }
            
        }
    }
    
    class func getUserBy(_ email:String) -> User?{
        let realm = try! Realm()
        
        return realm.object(ofType: User.self, forPrimaryKey: email)
    }
    
    class func getUsers() -> [User] {
        let realm = try! Realm()
        
        return Array(realm.objects(User.self))
    }
    
    class func restoreState(_ user:User) {
        let realm = try! Realm()
        
        try! realm.write() {
            user.inboxNextPageToken = "0"
            user.inboxHistoryId = 0
            
            user.draftNextPageToken = "0"
            user.draftHistoryId = 0
            
            user.sentNextPageToken = "0"
            user.sentHistoryId = 0
            
            user.junkNextPageToken = "0"
            user.junkHistoryId = 0
            
            user.trashNextPageToken = "0"
            user.trashHistoryId = 0
            
            user.allNextPageToken = "0"
            user.allHistoryId = 0
        }
    }
}

//MARK: - Account related
extension DBManager {
    class func store(_ account: Account){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(account, update: true)
        }
    }
    
    class func getAccountByUsername(_ username: String) -> Account? {
        let realm = try! Realm()
        
        return realm.object(ofType: Account.self, forPrimaryKey: username)
    }
}

//MARK: - Activity related
extension DBManager {
    
    class func store(_ activities:[Activity]){
        let realm = try! Realm()
        
        try! realm.write() {
            for activity in activities {
                realm.create(Activity.self, value: ["token": activity.token,
                                                    "subject": activity.subject,
                                                    "to": activity.to,
                                                    "toDisplayString": activity.toDisplayString,
                                                    "from": activity.from,
                                                    "type": activity.type,
                                                    "secondsSet": activity.secondsSet,
                                                    "isNew": activity.isNew,
                                                    "exists": activity.exists,
                                                    "timestamp": activity.timestamp,
                                                    "recallTime": activity.recallTime,
                                                    "openArraySerialized": activity.openArraySerialized], update: true)
            }
        }
    }
    
    class func getActivityBy(_ token:String) -> Activity?{
        let realm = try! Realm()
        
        if let activity = realm.object(ofType: Activity.self, forPrimaryKey: token) {
            activity.openArray = JSON(parseJSON: activity.openArraySerialized).arrayValue.map({$0.stringValue})
            return activity
        }
        
        
        return nil
    }
    
    class func getArrayActivities() -> [Activity]{
        let realm = try! Realm()
        
        var activities = Array(realm.objects(Activity.self).sorted(byKeyPath: "timestamp", ascending: false))
        for activity in activities{
            activity.openArray = JSON(parseJSON: activity.openArraySerialized).arrayValue.map({$0.stringValue})
            var opensList = [Open]()
            for open in activity.openArray{
                let location = open.components(separatedBy: ":")[0]
                let time = open.components(separatedBy: ":")[1]
                opensList.append(Open(fromTimestamp: Double(time)!, fromLocation: location, fromType: 1))
            }
            activity.openArrayObjects = opensList
        }
        activities = activities.sorted(by: { (activity1, activity2) -> Bool in
            
            if(activity1.openArrayObjects.count > 0 && activity2.openArrayObjects.count > 0){
                return Int((activity1.openArrayObjects.first?.timestamp)!) > Int((activity2.openArrayObjects.first?.timestamp)!)
            }
            else if(activity1.openArrayObjects.count > 0 && activity2.openArrayObjects.count == 0){
                return Int((activity1.openArrayObjects.first?.timestamp)!) > activity2.timestamp
            }
            else if(activity1.openArrayObjects.count == 0 && activity2.openArrayObjects.count > 0){
                return activity1.timestamp > Int((activity2.openArrayObjects.first?.timestamp)!)
            }
            
            return activity1.timestamp > activity2.timestamp
        })
        
        return activities
    }
    
    class func getAllActivities() -> [String:Activity]{
        let realm = try! Realm()
        
        let activities = Array(realm.objects(Activity.self).sorted(byKeyPath: "timestamp", ascending: false))
        var activityHash = [String:Activity]()
        for activity in activities{
            activity.openArray = JSON(parseJSON: activity.openArraySerialized).arrayValue.map({$0.stringValue})
            activityHash[activity.token] = activity
        }
        
        return activityHash
    }
    
    class func update(_ activity:Activity, exist:Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            activity.exists = exist
        }
    }
    
    class func update(_ activity:Activity, isMuted:Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            activity.isMuted = isMuted
        }
    }
    
    class func update(_ activity:Activity, recallTime:Int){
        let realm = try! Realm()
        
        try! realm.write() {
            activity.recallTime = recallTime
        }
    }
    
    class func update(_ activity:Activity, openArraySerialized:String){
        let realm = try! Realm()
        
        try! realm.write() {
            activity.openArraySerialized = openArraySerialized
        }
    }
    
    class func update(_ activity:Activity, hasOpens:Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            activity.hasOpens = hasOpens
        }
    }
    
    class func update(_ activity:Activity, isNew:Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            activity.isNew = isNew
        }
    }
    
}

//MARK: - Attachment related
extension DBManager {

    class func store(_ attachments:[AttachmentCriptext]){
        let realm = try! Realm()
        
        try! realm.write() {
            realm.add(attachments, update: true)
        }
    }
    
    class func getAttachmentBy(_ token:String) -> AttachmentCriptext?{
        let realm = try! Realm()
        
        if let attachment = realm.object(ofType: AttachmentCriptext.self, forPrimaryKey: token) {
            attachment.openArray = JSON(parseJSON: attachment.openArraySerialized).arrayValue.map({$0.stringValue})
            attachment.downloadArray = JSON(parseJSON: attachment.downloadArraySerialized).arrayValue.map({$0.stringValue})
            return attachment
        }
        
        return realm.object(ofType: AttachmentCriptext.self, forPrimaryKey: token)
    }
    
    class func getAttachmentsBy(_ token:String) -> [AttachmentCriptext]?{
        let realm = try! Realm()
        
        return Array(realm.objects(AttachmentCriptext.self).filter(NSPredicate(format: "token = %@", token)))
    }
    
    class func getAllAttachments() -> [String: [AttachmentCriptext]]{
        let realm = try! Realm()
        
        var result: [String: [AttachmentCriptext]] = [:]
        let attachments = realm.objects(AttachmentCriptext.self)
        for attachment in attachments{
            attachment.openArray = JSON(parseJSON: attachment.openArraySerialized).arrayValue.map({$0.stringValue})
            attachment.downloadArray = JSON(parseJSON: attachment.downloadArraySerialized).arrayValue.map({$0.stringValue})
            if(result[attachment.emailToken] == nil){
                result[attachment.emailToken] = [AttachmentCriptext]()
            }
            
            result[attachment.emailToken]!.append(attachment)
        }
        
        return result
    }
    
    
    
    class func getMails(from label:Label, since date:Date, current emailArray:[Email], current threadHash:[String:[Email]]) -> ([String:[Email]], [Email]) {
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "labelArraySerialized contains '\(label.id)' AND date < %@", date as CVarArg)
        let results = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: false)
        
        var threadIds:Set<String>!
        if results.count > 100 {
            //add all emails with the same date as the last one
            let datePredicate = NSPredicate(format: "labelArraySerialized contains '\(label.id)' AND date == %@ AND id != %@", results.last!.date! as CVarArg, results.last!.id)
            let sameDateEmails = realm.objects(Email.self).filter(datePredicate)
            
            threadIds = Set(results[0...100].map({return $0.threadId}))
            threadIds.formUnion(Set(sameDateEmails.map({return $0.threadId})))
        }else{
            threadIds = Set(results.map({return $0.threadId}))
        }
        
        let threadPredicate = NSPredicate(format: "threadId IN %@", threadIds)
        let trueResults = realm.objects(Email.self).filter(threadPredicate).sorted(byKeyPath: "date", ascending: false)
        
        var newThreadHash = [String:[Email]]()
        var newEmailArray = [Email]()
        
        for email in trueResults {
            email.labels = email.labelArraySerialized.components(separatedBy: ",")
            if label != .trash && email.labels.contains(Label.trash.id) {
                continue
            }
            
            if label != .junk && email.labels.contains(Label.junk.id) {
                continue
            }
            
            if threadHash[email.threadId] != nil {
                continue
            }
            
            if newThreadHash[email.threadId] == nil {
                newThreadHash[email.threadId] = []
            }
            
            newThreadHash[email.threadId]!.append(email)
            
            if newThreadHash[email.threadId]?.count == 1 && !emailArray.contains(where: { $0.threadId == email.threadId }) {
                newEmailArray.append(email)
            }
            
            email.criptextTokens = []
            
            if !email.criptextTokensSerialized.isEmpty {
                email.criptextTokens = email.criptextTokensSerialized.components(separatedBy: ",")
            }
        }
        
        return (newThreadHash, newEmailArray)
    }
    
    class func update(_ attachment:AttachmentCriptext, openArraySerialized:String){
        let realm = try! Realm()
        
        try! realm.write() {
            attachment.openArraySerialized = openArraySerialized
        }
    }
    
    class func update(_ attachment:AttachmentCriptext, downloadArraySerialized:String){
        let realm = try! Realm()
        
        try! realm.write() {
            attachment.downloadArraySerialized = downloadArraySerialized
        }
    }
    
    class func update(_ attachment:AttachmentGmail, isUploaded:Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            attachment.isUploaded = isUploaded
        }
    }
}

//MARK: - Email related
extension DBManager {

    class func store(_ email:Email){
        let realm = try! Realm()
        
        if let _ = realm.object(ofType: Email.self, forPrimaryKey: email.id) {
            return
        }
        
        try! realm.write() {
            realm.add(email, update: true)
        }
    }
    
    class func getMailBy(token:String) -> Email?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "realCriptextToken == '\(token)'")
        let results = realm.objects(Email.self).filter(predicate)
        
        return results.first
    }
    
    class func getPendingEmails() -> [Email]{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "needsSending == true")
        let results = realm.objects(Email.self).filter(predicate)
        
        return Array(results)
    }
    
    class func getPendingDrafts() -> [Email]{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "needsSaving == true")
        let results = realm.objects(Email.self).filter(predicate)
        
        return Array(results)
    }
    
    class func update(_ email:Email, labels:[String]){
        let realm = try! Realm()
        
        try! realm.write() {
            email.labelArraySerialized = labels.joined(separator: ",")
            email.labels = labels
        }
    }
    
    class func update(_ email:Email, snippet:String){
        let realm = try! Realm()
        
        try! realm.write() {
            email.snippet = snippet
        }
    }
    
    class func update(_ email:Email, nextPageToken:String?){
        let realm = try! Realm()
        
        try! realm.write() {
            email.nextPageToken = nextPageToken
        }
    }
    
    class func update(_ email:Email, realToken:String){
        let realm = try! Realm()
        
        try! realm.write() {
            email.realCriptextToken = realToken
        }
    }
    
    class func updateEmail(id:String, addLabels:[String]?, removeLabels:[String]?){
        let realm = try! Realm()
        
        guard let email = realm.object(ofType: Email.self, forPrimaryKey: id) else {
            return
        }
        
        email.labels = email.labelArraySerialized.components(separatedBy: ",")
        
        var newLabels = email.labels
        
        if let addLabels = addLabels {
            newLabels = Array(Set(newLabels + addLabels))
        }
        
        if let removeLabels = removeLabels {
            for label in removeLabels {
                newLabels = newLabels.filter{$0 != label}
            }
        }
        
        try! realm.write() {
            email.labelArraySerialized = newLabels.joined(separator: ",")
        }
    }
    
    class func deleteEmail(id:String){
        
        let realm = try! Realm()
        
        guard let email = realm.object(ofType: Email.self, forPrimaryKey: id) else {
            return
        }
        
        try! realm.write() {
            realm.delete(email)
        }
    }
    
    class func delete(_ email:Email){
        self.delete([email])
    }
    
    class func delete(_ emails:[Email]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(emails)
        }
    }
}

//MARK: - Contacts related
extension DBManager {

    class func store(_ contacts:[Contact]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(contacts, update: true)
        }
    }
    
    class func getContacts(_ text:String) -> [Contact]{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "email contains[c] '\(text)' OR displayName contains[c] '\(text)'")
        let results = realm.objects(Contact.self).filter(predicate)
        
        return Array(results)
    }
}

//MARK: - Keys related
extension DBManager {
    
    class func store(_ keyRecord: KeyRecord){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(keyRecord, update: true)
        }
    }
    
    class func store(_ keyRecords: [KeyRecord]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(keyRecords, update: true)
        }
    }
    
    class func getKeysRecords() -> [KeyRecord] {
        let realm = try! Realm()
        
        return Array(realm.objects(KeyRecord.self))
    }
    
    class func getKeyRecordById(id: Int32) -> KeyRecord?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "preKeyId == \(id)")
        let results = realm.objects(KeyRecord.self).filter(predicate)
        
        return results.first
    }
    
    class func deleteKeyRecord(id: Int32){
        let realm = try! Realm()
        guard let keyRecord = realm.object(ofType: KeyRecord.self, forPrimaryKey: id) else {
            return
        }
        try! realm.write() {
            realm.delete(keyRecord)
        }
    }
    
    class func store(_ keyRecord: SignedKeyRecord){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(keyRecord, update: true)
        }
    }
    
    class func store(_ keyRecords: [SignedKeyRecord]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(keyRecords, update: true)
        }
    }
    
    class func getKeysRecords() -> [SignedKeyRecord] {
        let realm = try! Realm()
        
        return Array(realm.objects(SignedKeyRecord.self))
    }
    
    class func getSignedKeyRecordById(id: Int32) -> SignedKeyRecord?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "signedPreKeyId == \(id)")
        let results = realm.objects(SignedKeyRecord.self).filter(predicate)
        
        return results.first
    }
    
    class func deleteSignedKeyRecord(id: Int32){
        let realm = try! Realm()
        guard let keyRecord = realm.object(ofType: SignedKeyRecord.self, forPrimaryKey: id) else {
            return
        }
        try! realm.write() {
            realm.delete(keyRecord)
        }
    }
    
    class func getAllSignedKeyRecords() -> [SignedKeyRecord]{
        let realm = try! Realm()
        
        return Array(realm.objects(SignedKeyRecord.self))
    }
}

//MARK: - Session related

extension DBManager {
    
    class func store(_ sessionRecord: RawSessionRecord){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(sessionRecord, update: true)
        }
    }
    
    class func getSessionRecord(contactId: String, deviceId: Int32) -> RawSessionRecord?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "contactId == '\(contactId)' AND deviceId == '\(deviceId)'")
        let results = realm.objects(RawSessionRecord.self).filter(predicate)
        
        return results.first
    }
    
    class func deleteSessionRecord(contactId: String, deviceId: Int32){
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "contactId == '\(contactId)' AND deviceId == '\(deviceId)'")
        let results = realm.objects(RawSessionRecord.self).filter(predicate)
        
        try! realm.write() {
            realm.delete(results)
        }
    }
    
    class func deleteAllSessions(contactId: String){
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "contactId == '\(contactId)'")
        let results = realm.objects(RawSessionRecord.self).filter(predicate)
        
        try! realm.write() {
            realm.delete(results)
        }
    }
    
    class func store(_ trustedDevice: TrustedDevice){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(trustedDevice, update: true)
        }
    }
    
    class func getTrustedDevice(recipientId: String) -> TrustedDevice?{
        let realm = try! Realm()
        
        guard let trustedDevice = realm.object(ofType: TrustedDevice.self, forPrimaryKey: recipientId) else {
            return nil
        }
        
        return trustedDevice
    }
}
