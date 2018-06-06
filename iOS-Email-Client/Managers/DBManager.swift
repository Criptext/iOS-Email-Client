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
    
    static let PAGINATION_SIZE = 20
    
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
    
    class func update(account: Account, name: String){
        let realm = try! Realm()
        
        try! realm.write() {
            account.name = name
        }
    }
    
    class func update(account: Account, signature: String, enabled: Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            account.signature = signature
            account.signatureEnabled = enabled
        }
    }
}

//MARK: - Device related

extension DBManager {
    class func store(_ device: Device){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(device, update: true)
        }
    }
    
    class func getDevices() -> [Device] {
        let realm = try! Realm()
        
        return Array(realm.objects(Device.self))
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
    
    class func getMails(from label: Int, since date:Date, limit: Int = PAGINATION_SIZE) -> [Email] {
        let emailsLimit = limit == 0 ? PAGINATION_SIZE : limit
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? []
        let predicate1 = NSPredicate(format: "NOT (ANY labels.id IN %@)", rejectedLabels)
        let predicate2 = NSPredicate(format: "ANY labels.id = %d AND NOT (ANY labels.id IN %@)", label, rejectedLabels)
        let predicate = label == SystemLabel.all.id ? predicate1 : predicate2
        let emails = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: false)
        let resultEmails = customDistinctEmailThreads(emails: emails, label: label, limit: emailsLimit, date: date, emailFilter: { (email) -> NSPredicate in
            guard label != SystemLabel.trash.id && label != SystemLabel.spam.id && label != SystemLabel.draft.id else {
                return NSPredicate(format: "ANY labels.id = %d AND threadId = %@", label, email.threadId)
            }
            return NSPredicate(format: "threadId = %@ AND NOT (ANY labels.id IN %@)", email.threadId, rejectedLabels)
        })
        return resultEmails
    }
    
    class func getUnreadMails(from label: Int) -> [Email] {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? []
        let emails = Array(realm.objects(Email.self).filter("ANY labels.id = %@ AND unread = true AND NOT (ANY labels.id IN %@)", label, rejectedLabels))
        var myEmails = [Email]()
        var threadIds = Set<String>()
        for email in emails {
            guard !threadIds.contains(email.threadId) else {
                continue
            }
            threadIds.insert(email.threadId)
            myEmails.append(email)
        }
        return myEmails
    }
    
    class func getThreadEmails(_ threadId: String, label: Int) -> [Email] {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? []
        let predicate1 = NSPredicate(format: "threadId == %@ AND NOT (ANY labels.id IN %@)", threadId, rejectedLabels)
        let predicate2 = NSPredicate(format: "ANY labels.id = %d AND threadId = %@", label, threadId)
        let predicate = label != SystemLabel.trash.id && label != SystemLabel.spam.id && label != SystemLabel.draft.id ? predicate1 : predicate2
        let results = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: true)
        
        return Array(results)
    }
    
    class func getMailsbyThreadId(_ threadId: String) -> [Email] {
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "threadId == '\(threadId)'")
        let results = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: true)
        
        return Array(results)
    }
    
    class func getMailByKey(key:String) -> Email?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "key == '\(key)'")
        let results = realm.objects(Email.self).filter(predicate)
        
        return results.first
    }
    
    class func getMails(since date:Date, searchParam: String, limit: Int = PAGINATION_SIZE) -> [Email] {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.all.rejectedLabelIds
        let emails = realm.objects(Email.self).filter("NOT (ANY labels.id IN %@) AND (ANY emailContacts.contact.displayName contains[cd] %@ OR preview contains[cd] %@ OR subject contains[cd] %@)", rejectedLabels, searchParam, searchParam, searchParam).sorted(byKeyPath: "date", ascending: false)
        return customDistinctEmailThreads(emails: emails, label: SystemLabel.all.id, limit: limit, date: date, emailFilter: { (email) -> NSPredicate in
            return NSPredicate(format: "threadId = %@ AND NOT (ANY labels.id IN %@)", email.threadId, rejectedLabels)
        })
    }
    
    private class func customDistinctEmailThreads(emails: Results<Email>, label: Int, limit: Int, date: Date, emailFilter: (Email) -> NSPredicate) -> [Email] {
        let realm = try! Realm()
        var resultEmails = [Email]()
        var threadIds = Set<String>()
        for email in emails {
            guard resultEmails.count < limit else {
                break
            }
            guard !email.labels.contains(where: {$0.id == SystemLabel.draft.id}) else {
                if(email.date < date){
                    resultEmails.append(email)
                    email.participants.formUnion(email.getContacts(type: .to))
                    email.participants.formUnion(email.getContacts(type: .cc))
                }
                continue
            }
            guard !threadIds.contains(email.threadId) else {
                continue
            }
            guard email.date < date else {
                threadIds.insert(email.threadId)
                continue
            }
            let threadEmails = realm.objects(Email.self).filter(emailFilter(email))
            for threadEmail in threadEmails {
                if(label == SystemLabel.sent.id){
                    if(threadEmail.labels.contains(where: {$0.id == SystemLabel.sent.id})){
                        email.participants.formUnion(threadEmail.getContacts(type: .to))
                        email.participants.formUnion(threadEmail.getContacts(type: .cc))
                    }
                }else{
                    email.participants.formUnion(threadEmail.getContacts(type: .from))
                }
            }
            email.counter = threadEmails.count
            threadIds.insert(email.threadId)
            resultEmails.append(email)
        }
        return resultEmails
    }
    
    public class func getThreadEmail(threadId: String, label: Int) -> Email? {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? []
        let threadsPredicate = NSPredicate(format: "ANY labels.id = %d AND NOT (ANY labels.id IN %@)", label, rejectedLabels)
        guard let email = realm.objects(Email.self).filter(threadsPredicate).sorted(byKeyPath: "date", ascending: false).first else {
            return nil
        }
        let predicate1 = NSPredicate(format: "threadId == %@ AND NOT (ANY labels.id IN %@)", threadId, rejectedLabels)
        let predicate2 = NSPredicate(format: "ANY labels.id = %d AND threadId = %@", label, threadId)
        let mailsPredicate = label != SystemLabel.trash.id && label != SystemLabel.spam.id && label != SystemLabel.draft.id ? predicate1 : predicate2
        email.counter = realm.objects(Email.self).filter(mailsPredicate).count
        return email
    }
    
    class func updateEmail(_ email: Email, key: String, messageId: String, threadId: String){
        let realm = try! Realm()
        
        try! realm.write() {
            email.key = key
            email.messageId = messageId
            email.threadId = threadId
            email.status = .sent
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
    
    class func deleteThreads(_ threadId: String, label: Int){
        let emails = getThreadEmails(threadId, label: label)
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
    
    class func update(_ session: CRSessionRecord, sessionString: String){
        let realm = try! Realm()
        
        try! realm.write() {
            session.sessionRecord = sessionString
        }
    }
    
    class func getSessionRecord(contactId: String, deviceId: Int32) -> CRSessionRecord?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "contactId == '\(contactId)' AND deviceId == \(deviceId)")
        let results = realm.objects(CRSessionRecord.self).filter(predicate)
        return results.first
    }
    
    class func getSessionRecords(recipientId: String) -> [CRSessionRecord] {
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "contactId == '\(recipientId)'")
        let results = realm.objects(CRSessionRecord.self).filter(predicate)
        return Array(results)
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
    
    class func getLabels(type: String) -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self).filter(NSPredicate(format: "type = %@", type)))
    }
    
    class func getLabel(_ labelId: Int) -> Label?{
        let realm = try! Realm()
        
        return realm.object(ofType: Label.self, forPrimaryKey: labelId)
    }
    
    class func getLabels() -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self))
    }
    
    class func getLabels(notIn ids: [Int]) -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self).filter(NSPredicate(format: "NOT (id IN %@)", ids)))
    }
    
    class func setLabelsForEmail(_ email: Email, labels: [Int]){
        let realm = try! Realm()
        try! realm.write {
            let keepLabels = email.labels.reduce(List<Label>(), { (labels, label) -> List<Label> in
                guard label.id == SystemLabel.draft.id || label.id == SystemLabel.sent.id else {
                    return labels
                }
                return labels + [label]
            })
            email.labels.removeAll()
            email.labels.append(objectsIn: keepLabels)
            for label in labels {
                guard label != SystemLabel.draft.id && label != SystemLabel.sent.id,
                let labelToAdd = getLabel(label)  else {
                    continue
                }
                email.labels.append(labelToAdd)
            }
        }
    }
    
    class func setLabelsForThread(_ threadId: String, labels: [Int], currentLabel: Int){
        let emails = getThreadEmails(threadId, label: currentLabel)
        for email in emails {
            setLabelsForEmail(email, labels: labels)
        }
    }
    
    class func addRemoveLabelsForThreads(_ threadId: String, addedLabelIds: [Int], removedLabelIds: [Int], currentLabel: Int){
        let emails = getThreadEmails(threadId, label: currentLabel)
        for email in emails {
            addRemoveLabelsFromEmail(email, addedLabelIds: addedLabelIds, removedLabelIds: removedLabelIds)
        }
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

//MARK: - File

extension DBManager {
    class func store(_ file: File){
        let realm = try! Realm()
        try! realm.write {
            realm.add(file, update: true)
        }
    }
    
    class func store(_ files: [File]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(files, update: true)
        }
    }
    
    class func update(file: File, emailId: String){
        let realm = try! Realm()
        
        try! realm.write() {
            file.emailId = emailId
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

