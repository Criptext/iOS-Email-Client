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
    
    class func refresh(){
        let realm = try! Realm()
        
        realm.refresh()
    }
    
    class func signout(){
        let realm = try! Realm()
        
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    class func retrieveWholeDB() -> [String: Any] {
        let realm = try! Realm()
        let contacts = realm.objects(Contact.self)
        let labels = realm.objects(Label.self)
        let emails = realm.objects(Email.self)
        let files = realm.objects(File.self)
        let emailContacts = realm.objects(EmailContact.self)
        
        return [
            "contacts": contacts,
            "labels": labels,
            "emails": emails,
            "files": files,
            "emailContacts": emailContacts
        ]
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
    
    class func update(account: Account, jwt: String){
        let realm = try! Realm()
        
        try! realm.write() {
            account.jwt = jwt
        }
    }
    
    class func update(account: Account, name: String){
        let realm = try! Realm()
        
        try! realm.write() {
            account.name = name
        }
    }
    
    class func update(account: Account, lastSeen: Date){
        let realm = try! Realm()
        
        try! realm.write() {
            account.lastTimeFeedOpened = lastSeen
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

//MARK: - Email related
extension DBManager {

    class func store(_ email:Email){
        let realm = try! Realm()
        
        try! realm.write() {
            if realm.object(ofType: Email.self, forPrimaryKey: email.key) != nil {
                return
            }
            realm.add(email, update: true)
        }
    }
    
    class func getMail(key: Int) -> Email? {
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "key == \(key)")
        let results = realm.objects(Email.self).filter(predicate)
        
        return results.first
    }
    
    class func getThreads(from label: Int, since date:Date, limit: Int = PAGINATION_SIZE) -> [Thread] {
        let emailsLimit = limit == 0 ? PAGINATION_SIZE : limit
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? [SystemLabel.spam.id, SystemLabel.trash.id]
        let predicate1 = NSPredicate(format: "NOT (ANY labels.id IN %@)", rejectedLabels)
        let predicate2 = NSPredicate(format: "ANY labels.id = %d AND NOT (ANY labels.id IN %@)", label, rejectedLabels)
        let predicate = label == SystemLabel.all.id ? predicate1 : predicate2
        let emails = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: false)
        let threads = customDistinctEmailThreads(emails: emails, label: label, limit: emailsLimit, date: date, emailFilter: { (email) -> NSPredicate in
            guard label != SystemLabel.trash.id && label != SystemLabel.spam.id && label != SystemLabel.draft.id else {
                return NSPredicate(format: "ANY labels.id = %d AND threadId = %@", label, email.threadId)
            }
            return NSPredicate(format: "threadId = %@ AND NOT (ANY labels.id IN %@)", email.threadId, rejectedLabels)
        })
        return threads
    }
    
    class func getThreads(since date:Date, searchParam: String, limit: Int = PAGINATION_SIZE) -> [Thread] {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.all.rejectedLabelIds
        let emails = realm.objects(Email.self).filter("NOT (ANY labels.id IN %@) AND (ANY emailContacts.contact.displayName contains[cd] %@ OR preview contains[cd] %@ OR subject contains[cd] %@)", rejectedLabels, searchParam, searchParam, searchParam).sorted(byKeyPath: "date", ascending: false)
        return customDistinctEmailThreads(emails: emails, label: SystemLabel.all.id, limit: limit, date: date, emailFilter: { (email) -> NSPredicate in
            return NSPredicate(format: "threadId = %@ AND NOT (ANY labels.id IN %@)", email.threadId, rejectedLabels)
        })
    }
    
    private class func customDistinctEmailThreads(emails: Results<Email>, label: Int, limit: Int, date: Date, emailFilter: (Email) -> NSPredicate) -> [Thread] {
        let realm = try! Realm()
        var threads = [Thread]()
        var threadIds = Set<String>()
        for email in emails {
            let thread = Thread()
            thread.date = email.date
            thread.threadId = email.threadId
            thread.lastEmail = email
            guard threads.count < limit else {
                break
            }
            guard !email.labels.contains(where: {$0.id == SystemLabel.draft.id}) else {
                if(email.date < date){
                    thread.subject = email.subject
                    thread.participants.formUnion(email.getContacts(type: .to))
                    thread.participants.formUnion(email.getContacts(type: .cc))
                    threads.append(thread)
                }
                continue
            }
            guard !threadIds.contains(email.threadId) else {
                continue
            }
            guard email.date < date else {
                threadIds.insert(thread.threadId)
                continue
            }
            let threadEmails = realm.objects(Email.self).filter(emailFilter(email)).sorted(byKeyPath: "date", ascending: true)
            thread.lastEmail = threadEmails.last ?? email
            thread.threadId = thread.lastEmail.threadId
            for threadEmail in threadEmails {
                if(label == SystemLabel.sent.id){
                    if(threadEmail.labels.contains(where: {$0.id == SystemLabel.sent.id})){
                        thread.participants.formUnion(threadEmail.getContacts(type: .to))
                        thread.participants.formUnion(threadEmail.getContacts(type: .cc))
                    }
                }else{
                    thread.participants.formUnion(threadEmail.getContacts(type: .from))
                }
                if(!thread.hasAttachments && threadEmail.files.count > 0){
                    thread.hasAttachments = true
                }
            }
            thread.unread = threadEmails.contains(where: {$0.unread})
            thread.counter = threadEmails.count
            thread.subject = threadEmails.first!.subject
            threadIds.insert(thread.threadId)
            threads.append(thread)
        }
        return threads
    }
    
    public class func getThread(threadId: String, label: Int) -> Thread? {
        let thread = Thread()
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? [SystemLabel.spam.id, SystemLabel.trash.id]
        let threadsPredicate = NSPredicate(format: "threadId == %@ AND ANY labels.id = %d AND NOT (ANY labels.id IN %@)", threadId, label, rejectedLabels)
        guard let email = realm.objects(Email.self).filter(threadsPredicate).sorted(byKeyPath: "date", ascending: false).first else {
            return nil
        }
        thread.date = email.date
        let predicate1 = NSPredicate(format: "threadId == %@ AND NOT (ANY labels.id IN %@)", threadId, rejectedLabels)
        let predicate2 = NSPredicate(format: "ANY labels.id = %d AND threadId = %@", label, threadId)
        let mailsPredicate = label != SystemLabel.trash.id && label != SystemLabel.spam.id && label != SystemLabel.draft.id ? predicate1 : predicate2
        let threadEmails = realm.objects(Email.self).filter(mailsPredicate).sorted(byKeyPath: "date", ascending: true)
        for threadEmail in threadEmails {
            if(label == SystemLabel.sent.id){
                if(threadEmail.labels.contains(where: {$0.id == SystemLabel.sent.id})){
                    thread.participants.formUnion(threadEmail.getContacts(type: .to))
                    thread.participants.formUnion(threadEmail.getContacts(type: .cc))
                }
            }else{
                thread.participants.formUnion(threadEmail.getContacts(type: .from))
            }
            if(!thread.hasAttachments && threadEmail.files.count > 0){
                thread.hasAttachments = true
            }
        }
        thread.lastEmail = threadEmails.last ?? email
        thread.threadId = thread.lastEmail.threadId
        thread.unread = threadEmails.contains(where: {$0.unread})
        thread.subject = threadEmails.first!.subject
        thread.counter = threadEmails.count
        return thread
    }
    
    class func getThreadEmails(_ threadId: String, label: Int) -> [Email] {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? []
        let predicate1 = NSPredicate(format: "threadId == %@ AND NOT (ANY labels.id IN %@)", threadId, rejectedLabels)
        let predicate2 = NSPredicate(format: "ANY labels.id = %d AND threadId = %@", label, threadId)
        let predicate = (label == SystemLabel.trash.id || label == SystemLabel.spam.id || label == SystemLabel.draft.id) ? predicate2 : predicate1
        let results = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: true)
        
        return Array(results)
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
    
    class func getMailByKey(key: Int) -> Email?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "key == \(key)")
        let results = realm.objects(Email.self).filter(predicate)
        
        return results.first
    }
    
    class func updateEmail(_ email: Email, status: Email.Status){
        let realm = try! Realm()
        
        try! realm.write() {
            email.status = status
        }
    }
    
    class func updateEmail(_ email: Email, password: String){
        let realm = try! Realm()
        
        try! realm.write() {
            email.password = password
        }
    }
    
    class func updateEmail(_ email: Email, secure: Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            email.secure = secure
        }
    }
    
    class func updateEmail(_ email: Email, key: Int, messageId: String, threadId: String) {
        let realm = try! Realm()
        try! realm.write() {
            if let fileKey = getFileKey(emailId: email.key) {
                fileKey.emailId = key
            }
            
            let newEmail = Email()
            newEmail.key = key
            newEmail.messageId = messageId
            newEmail.threadId = threadId
            newEmail.status = .sent
            newEmail.unread = false
            newEmail.secure = email.secure
            newEmail.subject = email.subject
            newEmail.content = email.content
            newEmail.preview = email.preview
            newEmail.date = email.date
            newEmail.unsentDate = email.unsentDate
            newEmail.isMuted = email.isMuted
            newEmail.password = nil
            newEmail.labels.append(objectsIn: email.labels)
            newEmail.files.append(objectsIn: email.files)
            
            realm.add(newEmail)
            
            let emailContacts = getEmailContacts(emailKey: email.key)
            for emailContact in emailContacts {
                emailContact.email = newEmail
            }
            
            realm.delete(email)
        }
    }
    
    class func updateEmail(_ email: Email, unread: Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            email.unread = unread
        }
    }
    
    class func updateEmail(_ email: Email, muted: Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            email.isMuted = muted
        }
    }
    
    class func deleteEmail(id: Int){
        
        let realm = try! Realm()
        
        guard let email = realm.object(ofType: Email.self, forPrimaryKey: id) else {
            return
        }
        
        try! realm.write() {
            self.deleteEmail(realm: realm, emails: [email])
        }
    }
    
    class func delete(_ email:Email){
        let realm = try! Realm()
        
        try! realm.write {
            self.deleteEmail(realm: realm, emails: [email])
        }
    }
    
    class func delete(_ emails:[Email]){
        let realm = try! Realm()
        
        try! realm.write {
            self.deleteEmail(realm: realm, emails: emails)
        }
    }
    
    class func deleteDraftInComposer(_ draft: Email){
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(draft.emailContacts)
            if let fileKey = self.getFileKey(emailId: draft.key){
                realm.delete(fileKey)
            }
            realm.delete(draft)
        }
    }
    
    class func deleteThreads(_ threadId: String, label: Int){
        let emails = getThreadEmails(threadId, label: label)
        let realm = try! Realm()
        
        try! realm.write {
            self.deleteEmail(realm: realm, emails: emails)
        }
    }
    
    class func updateThread(threadId: String, currentLabel: Int, unread: Bool){
        let emails = getThreadEmails(threadId, label: currentLabel)
        for email in emails {
            updateEmail(email, unread: unread)
        }
    }
    
    class func getEmailFailed() -> Email? {
        let realm = try! Realm()
        let hasFailed = NSPredicate(format: "delivered == \(Email.Status.fail.rawValue) AND NOT (ANY labels.id IN %@)", [SystemLabel.trash.id])
        let results = realm.objects(Email.self).filter(hasFailed)
        
        return results.first
    }
    
    class func unsendEmail(_ email: Email, date: Date = Date()){
        let realm = try! Realm()
        
        try! realm.write() {
            email.content = ""
            email.preview = ""
            email.unsentDate = date
            email.status = .unsent
            
            email.files.forEach({ (file) in
                file.name = ""
                file.size = 0
                file.mimeType = ""
                file.status = 0
            })
        }
    }
}

//MARK: - Contacts related
extension DBManager {

    class func store(_ contacts:[Contact]){
        let realm = try! Realm()
        
        try! realm.write {
            contacts.forEach({ (contact) in
                contact.id = (realm.objects(Contact.self).max(ofProperty: "id") as Int? ?? 0) + 1
                realm.add(contacts, update: true)
            })
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
    
    class func update(contact: Contact, name: String){
        let realm = try! Realm()
        try! realm.write {
            contact.displayName = name
        }
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
    
    class func getAllKeyRecords() -> [CRPreKeyRecord]{
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
    
    class func store(_ label: Label, incrementId: Bool = false){
        let realm = try! Realm()
        try! realm.write {
            guard realm.objects(Label.self).filter("text == '\(label.text)'").first == nil else {
                return
            }
            if(incrementId){
                label.incrementID()
            }
            realm.add(label, update: true)
        }
    }
    
    class func updateLabel(_ label: Label, visible: Bool){
        let realm = try! Realm()
        try! realm.write {
            label.visible = visible
        }
    }
    
    class func getLabels(type: String) -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self).filter(NSPredicate(format: "type = %@", type)))
    }
    
    class func getActiveCustomLabels() -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self).filter(NSPredicate(format: "type = 'custom' and visible = true")))
    }
    
    class func getLabel(_ labelId: Int) -> Label?{
        let realm = try! Realm()
        
        return realm.object(ofType: Label.self, forPrimaryKey: labelId)
    }
    
    class func getLabel(text: String) -> Label?{
        let realm = try! Realm()
        
        return realm.objects(Label.self).filter(NSPredicate(format: "text = %@", text)).first
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
            file.id = (realm.objects(File.self).max(ofProperty: "id") as Int? ?? 0) + 1
            realm.add(file, update: true)
        }
    }
    
    class func store(_ files: [File]){
        let realm = try! Realm()
        
        try! realm.write {
            files.forEach({ (file) in
                file.id = (realm.objects(File.self).max(ofProperty: "id") as Int? ?? 0) + 1
                realm.add(files, update: true)
            })
        }
    }
    
    class func getFile(_ filetoken: String) -> File?{
        let realm = try! Realm()
        
        return realm.object(ofType: File.self, forPrimaryKey: filetoken)
    }
    
    class func update(filetoken: String, emailId: Int){
        guard let file = getFile(filetoken) else {
            return
        }
        
        let realm = try! Realm()
        try! realm.write() {
            file.emailId = emailId
        }
    }
    
    class func delete(_ files: [File]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(files)
        }
    }
}

//MARK: - Feed

extension DBManager {
    
    class func store(_ feed: FeedItem){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(feed, update: true)
        }
    }
    
    class func feedExists(emailId: Int, type: Int, contactId: String) -> Bool {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "contact.email == '\(contactId)' AND email.key == \(emailId) AND type == \(type)")
        let results = realm.objects(FeedItem.self).filter(predicate)
        return results.count > 0
    }
    
    class func getFeeds(since date: Date, limit: Int, lastSeen: Date) -> (Results<FeedItem>, Results<FeedItem>){
        let realm = try! Realm()
        
        let newFeeds = realm.objects(FeedItem.self).filter("date > %@", lastSeen).sorted(byKeyPath: "date", ascending: false)
        let oldFeeds = realm.objects(FeedItem.self).filter("date <= %@", lastSeen).sorted(byKeyPath: "date", ascending: false)
        
        return (newFeeds, oldFeeds)
    }
    
    class func getNewFeedsCount(since date: Date) -> Int{
        let realm = try! Realm()
        
        let feeds = realm.objects(FeedItem.self).filter("date > %@", date).sorted(byKeyPath: "date", ascending: false)
        return feeds.count
    }
    
    class func delete(feed: FeedItem){
        let realm = try! Realm()

        try! realm.write() {
            realm.delete(feed)
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
    
    class func getEmailContacts(emailKey: Int) -> [EmailContact] {
        let realm = try! Realm()
        
        return Array(realm.objects(EmailContact.self).filter("email.key == \(emailKey)"))
    }
}

//MARK: - FileKey
extension DBManager {
    
    class func store(_ fileKeys: [FileKey]){
        let realm = try! Realm()
        
        try! realm.write {
            for fileKey in fileKeys {
                fileKey.incrementID()
                realm.add(fileKey, update: true)
            }
        }
    }
    
    class func getFileKey(emailId: Int) -> FileKey? {
        let realm = try! Realm()
        
        return realm.objects(FileKey.self).filter("emailId == %@", emailId).first
    }
}

//MARK: - Peer Events
extension DBManager {
    
    class func markAsUnread(emailKeys: [Int], unread: Bool){
        let realm = try! Realm()
        
        try! realm.write {
            for key in emailKeys {
                guard let email = realm.objects(Email.self).filter("key == \(key)").first else {
                    continue
                }
                email.unread = unread
            }
        }
    }
    
    class func markAsUnread(threadIds: [String], unread: Bool){
        let realm = try! Realm()
        
        try! realm.write {
            for threadId in threadIds {
                let emails = realm.objects(Email.self).filter("threadId == '\(threadId)'")
                emails.forEach({ (email) in
                    email.unread = unread
                })
            }
        }
    }
    
    class func addRemoveLabels(emailKeys: [Int], addedLabelNames: [String], removedLabelNames: [String]){
        let realm = try! Realm()
        
        try! realm.write {
            for key in emailKeys {
                guard let email = realm.objects(Email.self).filter("key == \(key)").first else {
                    continue
                }
                self.addRemoveLabels(realm: realm, email: email, addedLabelNames: addedLabelNames, removedLabelNames: removedLabelNames)
            }
        }
    }
    
    class func addRemoveLabels(threadIds: [String], addedLabelNames: [String], removedLabelNames: [String]){
        let realm = try! Realm()
        
        try! realm.write {
            for threadId in threadIds {
                let emails = realm.objects(Email.self).filter("threadId == '\(threadId)'")
                for email in emails {
                    self.addRemoveLabels(realm: realm, email: email, addedLabelNames: addedLabelNames, removedLabelNames: removedLabelNames)
                }
            }
        }
    }
    
    class func addRemoveLabels(realm: Realm, email: Email, addedLabelNames: [String], removedLabelNames: [String]){
        for labelName in addedLabelNames {
            guard !email.labels.contains(where: {$0.text == labelName}),
                let label = realm.objects(Label.self).filter("text == '\(labelName)'").first else {
                    continue
            }
            email.labels.append(label)
        }
        for labelName in removedLabelNames {
            guard let index = email.labels.index(where: {$0.text == labelName}) else {
                continue
            }
            email.labels.remove(at: index)
        }
    }
    
    class func deleteEmails(emailKeys: [Int]){
        let realm = try! Realm()
        
        try! realm.write {
            for key in emailKeys {
                guard let email = realm.objects(Email.self).filter("key == \(key)").first,
                    email.labels.contains(where: {$0.id == SystemLabel.trash.id || $0.id == SystemLabel.draft.id || $0.id == SystemLabel.spam.id}) else {
                    continue
                }
                self.deleteEmail(realm: realm, emails: [email])
            }
        }
    }
    
    class func deleteThreads(threadIds: [String]){
        let realm = try! Realm()
        
        try! realm.write {
            for threadId in threadIds {
                let deletableLabels = [SystemLabel.trash.id, SystemLabel.spam.id, SystemLabel.draft.id]
                let emails = Array(realm.objects(Email.self).filter("threadId == '\(threadId)' AND ANY labels.id IN %@", deletableLabels))
                self.deleteEmail(realm: realm, emails: emails)
            }
        }
    }
    
    class func deleteEmail(realm: Realm, emails: [Email]){
        emails.forEach({ (email) in
            realm.delete(email.files)
            realm.delete(email.emailContacts)
            realm.delete(realm.objects(FeedItem.self).filter("email.key == \(email.key)"))
            if let fileKey = self.getFileKey(emailId: email.key){
                realm.delete(fileKey)
            }
        })
        realm.delete(emails)
    }
    
    class func updateAccount(recipientId: String, name: String){
        let realm = try! Realm()
        
        try! realm.write {
            if let account = realm.object(ofType: Account.self, forPrimaryKey: recipientId) {
                account.name = name
            }
            if let contact = realm.object(ofType: Contact.self, forPrimaryKey: "\(recipientId)\(Constants.domain)") {
                contact.displayName = name
            }
        }
    }
}
