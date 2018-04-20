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

//MARK: - Email related
extension DBManager {

    class func store(_ email:Email){
        let realm = try! Realm()
        
        if let _ = realm.object(ofType: Email.self, forPrimaryKey: email.id) {
            return
        }
        email.id = email.incrementID()
        try! realm.write() {
            realm.add(email, update: true)
        }
    }
    
    class func getMails(from label: Int, since date:Date) -> ([String:[Email]], [Email]) {
        var threadIds = Set<String>()
        let realm = try! Realm()
        let emails = Array(realm.objects(Email.self).filter("ANY labels.id = %@", label)).sorted(by: {$0.date! > $1.date!})
        return ([:], emails)
    }
    
    class func getMailsbyThreadId(_ threadId: String, label: Int) -> [Email] {
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "threadId == '\(threadId)'")
        let results = realm.objects(Email.self).filter(predicate)
        
        return Array(results)
    }
    
    class func getMailByKey(key:String) -> Email?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "key == '\(key)'")
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
        
//        try! realm.write() {
//            email.labelArraySerialized = labels.joined(separator: ",")
//            email.labels = labels
//        }
    }
    
    class func update(_ email:Email, snippet:String){
        let realm = try! Realm()
        
//        try! realm.write() {
//            email.snippet = snippet
//        }
    }
    
    class func update(_ email:Email, nextPageToken:String?){
        let realm = try! Realm()
        
//        try! realm.write() {
//            email.nextPageToken = nextPageToken
//        }
    }
    
    class func update(_ email:Email, realToken:String){
        let realm = try! Realm()
        
//        try! realm.write() {
//            email.realCriptextToken = realToken
//        }
    }
    
    class func updateEmail(id:String, addLabels:[String]?, removeLabels:[String]?){
        let realm = try! Realm()
        
        guard let email = realm.object(ofType: Email.self, forPrimaryKey: id) else {
            return
        }
    }
    
    class func updateEmail(_ email: Email, key: String, s3Key: String, threadId: String){
        let realm = try! Realm()
        
        try! realm.write() {
            email.key = key
            email.s3Key = s3Key
            email.threadId = threadId
        }
    }
    
    class func updateEmail(_ email: Email, unread: Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            email.unread = unread
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
    
    class func getContact(_ email:String) -> Contact?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "email == '\(email)'")
        let results = realm.objects(Contact.self).filter(predicate)
        
        return results.first
    }
    
}

//MARK: - Keys related
extension DBManager {
    
    class func store(_ keyRecord: CRPreKeyRecord){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(keyRecord, update: true)
        }
    }
    
    class func store(_ keyRecords: [CRPreKeyRecord]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(keyRecords, update: true)
        }
    }
    
    class func getKeysRecords() -> [CRPreKeyRecord] {
        let realm = try! Realm()
        
        return Array(realm.objects(CRPreKeyRecord.self))
    }
    
    class func getKeyRecordById(id: Int32) -> CRPreKeyRecord?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "preKeyId == \(id)")
        let results = realm.objects(CRPreKeyRecord.self).filter(predicate)
        
        return results.first
    }
    
    class func deleteKeyRecord(id: Int32){
        let realm = try! Realm()
        guard let keyRecord = realm.object(ofType: CRPreKeyRecord.self, forPrimaryKey: id) else {
            return
        }
        try! realm.write() {
            realm.delete(keyRecord)
        }
    }
    
    class func store(_ keyRecord: CRSignedPreKeyRecord){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(keyRecord, update: true)
        }
    }
    
    class func store(_ keyRecords: [CRSignedPreKeyRecord]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(keyRecords, update: true)
        }
    }
    
    class func getKeysRecords() -> [CRSignedPreKeyRecord] {
        let realm = try! Realm()
        
        return Array(realm.objects(CRSignedPreKeyRecord.self))
    }
    
    class func getSignedKeyRecordById(id: Int32) -> CRSignedPreKeyRecord?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "signedPreKeyId == \(id)")
        let results = realm.objects(CRSignedPreKeyRecord.self).filter(predicate)
        
        return results.first
    }
    
    class func deleteSignedKeyRecord(id: Int32){
        let realm = try! Realm()
        guard let keyRecord = realm.object(ofType: CRSignedPreKeyRecord.self, forPrimaryKey: id) else {
            return
        }
        try! realm.write() {
            realm.delete(keyRecord)
        }
    }
    
    class func getAllSignedKeyRecords() -> [CRSignedPreKeyRecord]{
        let realm = try! Realm()
        
        return Array(realm.objects(CRSignedPreKeyRecord.self))
    }
}

//MARK: - Session related

extension DBManager {
    
    class func store(_ sessionRecord: CRSessionRecord){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(sessionRecord, update: true)
        }
    }
    
    class func getSessionRecord(contactId: String, deviceId: Int32) -> CRSessionRecord?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "contactId == '\(contactId)' AND deviceId == \(deviceId)")
        let results = realm.objects(CRSessionRecord.self).filter(predicate)
        return results.first
    }
    
    class func deleteSessionRecord(contactId: String, deviceId: Int32){
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "contactId == '\(contactId)' AND deviceId == \(deviceId)")
        let results = realm.objects(CRSessionRecord.self).filter(predicate)
        
        try! realm.write() {
            realm.delete(results)
        }
    }
    
    class func deleteAllSessions(contactId: String){
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "contactId == '\(contactId)'")
        let results = realm.objects(CRSessionRecord.self).filter(predicate)
        
        try! realm.write() {
            realm.delete(results)
        }
    }
    
    class func store(_ trustedDevice: CRTrustedDevice){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(trustedDevice, update: true)
        }
    }
    
    class func getTrustedDevice(recipientId: String) -> CRTrustedDevice?{
        let realm = try! Realm()
        
        guard let trustedDevice = realm.object(ofType: CRTrustedDevice.self, forPrimaryKey: recipientId) else {
            return nil
        }
        
        return trustedDevice
    }
    
    //MARK: - Labels
    
    class func store(_ label: Label){
        let realm = try! Realm()
        try! realm.write {
            realm.add(label, update: true)
        }
    }
    
    class func getLabel(_ labelId: Int) -> Label?{
        let realm = try! Realm()
        
        return realm.object(ofType: Label.self, forPrimaryKey: labelId)
    }
    
    class func getLabels() -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self))
    }
    
    class func addRemoveLabelsFromEmail(_ email: Email, addedLabelIds: [Int], removedLabelIds: [Int]){
        let realm = try! Realm()
        try! realm.write {
            for labelId in addedLabelIds {
                guard !email.labels.contains(where: {$0.id == labelId}),
                    let label = self.getLabel(labelId) else {
                    continue
                }
                email.labels.append(label)
            }
            for labelId in removedLabelIds {
                guard let index = email.labels.index(where: {$0.id == labelId}) else {
                    continue
                }
                email.labels.remove(at: index)
            }
        }
    }
    
}

//MARK: - Email Contact

extension DBManager {
    
    class func store(_ emailContacts:[EmailContact]){
        let realm = try! Realm()
        
        try! realm.write {
            for emailContact in emailContacts {
                emailContact.incrementID()
                realm.add(emailContact, update: true)
            }
        }
    }
    
    class func getEmailContacts() -> [EmailContact] {
        let realm = try! Realm()
        
        return Array(realm.objects(EmailContact.self))
    }
}

