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
class DBManager: SharedDB {
    
    static let PAGINATION_SIZE = 20
    
    class func signout(){
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(realm.objects(CRSignedPreKeyRecord.self))
            realm.delete(realm.objects(CRPreKeyRecord.self))
            realm.delete(realm.objects(CRSessionRecord.self))
            realm.delete(realm.objects(CRTrustedDevice.self))
        }
    }
    
    class func clearMailbox(){
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(realm.objects(Email.self))
            realm.delete(realm.objects(Contact.self))
            realm.delete(realm.objects(FeedItem.self))
            realm.delete(realm.objects(EmailContact.self))
            realm.delete(realm.objects(Label.self))
            realm.delete(realm.objects(File.self))
            realm.delete(realm.objects(QueueItem.self))
            realm.delete(realm.objects(DummySession.self))
        }
        createSystemLabels()
    }
    
    class func destroy(){
        let realm = try! Realm()
        
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    class func createSystemLabels(){
        for systemLabel in SystemLabel.array {
            let newLabel = Label(systemLabel.description)
            newLabel.id = systemLabel.id
            newLabel.color = systemLabel.hexColor
            newLabel.type = "system"
            DBManager.store(newLabel)
        }
    }
    
    class func retrieveWholeDB() -> LinkDBSource {
        let realm = try! Realm()
        let contacts = realm.objects(Contact.self)
        let labels = realm.objects(Label.self).filter("type == 'custom'")
        let emails = realm.objects(Email.self).filter("messageId != ''")
        let files = realm.objects(File.self)
        let emailContacts = realm.objects(EmailContact.self).filter("email.delivered != \(Email.Status.sending.rawValue) AND email.delivered != \(Email.Status.fail.rawValue) AND NOT (ANY email.labels.id == \(SystemLabel.draft.id))")
        return LinkDBSource(contacts: contacts, labels: labels, emails: emails, emailContacts: emailContacts, files: files)
    }
    
    struct LinkDBSource {
        let contacts: Results<Contact>
        let labels: Results<Label>
        let emails: Results<Email>
        let emailContacts: Results<EmailContact>
        let files: Results<File>
    }
    
    struct LinkDBMaps {
        var emails: [Int: Int]
        var contacts: [Int: String]
    }
    
    class func insertBatchRows(rows: [[String: Any]], maps: inout LinkDBMaps){
        let realm = try! Realm()
        try! realm.write {
            for row in rows {
                self.insertRow(realm: realm, row: row, maps: &maps)
            }
        }
    }
    
    class func insertRow(realm: Realm, row: [String: Any], maps: inout LinkDBMaps){
        guard let table = row["table"] as? String,
            let object = row["object"] as? [String: Any] else {
                return
        }
        switch(table){
        case "contact":
            let contact = Contact()
            let contactId = object["id"] as! Int
            contact.email = object["email"] as! String
            contact.displayName = object["name"] as? String ?? String(contact.email.split(separator: "@").first!)
            realm.add(contact, update: true)
            maps.contacts[contactId] = contact.email
        case "label":
            let label = Label()
            label.id = object["id"] as! Int
            label.visible = object["visible"] as! Bool
            label.color = object["color"] as! String
            label.text = object["text"] as! String
            realm.add(label, update: true)
        case "email":
            let id = object["id"] as! Int
            let email = Email()
            email.content = object["content"] as! String
            email.messageId = (object["messageId"] as? Int)?.description ?? object["messageId"] as! String
            email.isMuted = object["isMuted"] as! Bool
            email.threadId = object["threadId"] as! String
            email.unread = object["unread"] as! Bool
            email.secure = object["secure"] as! Bool
            email.preview = object["preview"] as! String
            email.delivered = object["status"] as! Int
            email.key = object["key"] as! Int
            email.subject = object["subject"] as? String ?? ""
            email.date = EventData.convertToDate(dateString: object["date"] as! String)
            if let unsentDate = object["unsentDate"] as? String {
                email.unsentDate = EventData.convertToDate(dateString: unsentDate)
            }
            if let trashDate = object["trashDate"] as? String {
                email.trashDate = EventData.convertToDate(dateString: trashDate)
            }
            realm.add(email, update: true)
            maps.emails[id] = email.key
        case "email_label":
            let labelId = object["labelId"] as! Int
            let emailId = object["emailId"] as! Int
            guard let emailKey = maps.emails[emailId],
                let email = realm.object(ofType: Email.self, forPrimaryKey: emailKey),
                let label = realm.object(ofType: Label.self, forPrimaryKey: labelId) else {
                    return
            }
            email.labels.append(label)
        case "email_contact":
            let contactId = object["contactId"] as! Int
            let emailId = object["emailId"] as! Int
            guard let emailKey = maps.emails[emailId],
                let contactEmail = maps.contacts[contactId],
                let contact = realm.object(ofType: Contact.self, forPrimaryKey: contactEmail),
                let email = realm.object(ofType: Email.self, forPrimaryKey: emailKey) else {
                    return
            }
            let emailContact = EmailContact()
            emailContact.contact = contact
            emailContact.email = email
            emailContact.type = (object["type"] as! String).lowercased()
            emailContact.compoundKey = emailContact.buildCompoundKey()
            realm.add(emailContact, update: true)
        case "file":
            let emailId = object["emailId"] as! Int
            guard let emailKey = maps.emails[emailId],
                let email = realm.object(ofType: Email.self, forPrimaryKey: emailKey) else {
                return
            }
            let file = File()
            file.name = object["name"] as! String
            file.status = object["status"] as! Int
            file.emailId = emailKey
            file.token = object["token"] as! String
            file.readOnly = (object["readOnly"] as! Bool) ? 1 : 0
            file.size = object["size"] as! Int
            file.mimeType = object["mimeType"] as! String
            if let fileKey = object["fileKey"]{
                file.fileKey = fileKey as! String
            }
            file.date = EventData.convertToDate(dateString: object["date"] as! String)
            realm.add(file, update: true)
            email.files.append(file)
        case "filekey":
            let key = object["key"] as? String
            let iv = object["iv"] as? String
            let emailId = object["emailId"] as! Int
            let fileKey = key != nil && iv != nil ? "\(key!):\(iv!)" : ""
            guard let emailKey = maps.emails[emailId],
                let email = realm.object(ofType: Email.self, forPrimaryKey: emailKey) else {
                    return
            }
            for file in email.files{
                file.fileKey = fileKey
            }
        default:
            return
        }
    }

    //MARK: - Account related
    
    class func store(_ account: Account){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(account, update: true)
        }
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

    //MARK: - Email related

    @discardableResult class func store(_ email:Email, update: Bool = true) -> Bool {
        let realm = try! Realm()
        
        do {
            try realm.write() {
                if realm.object(ofType: Email.self, forPrimaryKey: email.key) != nil {
                    return
                }
                realm.add(email, update: update)
            }
            return true
        } catch {
            return false
        }
    }
    
    class func getMail(key: Int) -> Email? {
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "key == \(key)")
        let results = realm.objects(Email.self).filter(predicate)
        
        return results.first
    }
    
    class func countMails() -> Int {
        let realm = try! Realm()
        
        return realm.objects(Email.self).count
    }
    
    class func getThreads(from label: Int, since date:Date, limit: Int = PAGINATION_SIZE, threadIds: [String] = []) -> [Thread] {
        let emailsLimit = limit == 0 ? PAGINATION_SIZE : limit
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? [SystemLabel.spam.id, SystemLabel.trash.id]
        let predicate = NSPredicate(format: "NOT (ANY labels.id IN %@) AND NOT (threadId IN %@)", rejectedLabels, threadIds)
        let emails = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: false).distinct(by: ["threadId"]).filter("date < %@", date)
        let threads = customDistinctEmailThreads(emails: emails, label: label, limit: emailsLimit, date: date, emailFilter: { (email) -> NSPredicate in
            guard label != SystemLabel.trash.id && label != SystemLabel.spam.id && label != SystemLabel.draft.id else {
                return NSPredicate(format: "ANY labels.id = %d AND threadId = %@ ", label, email.threadId)
            }
            return NSPredicate(format: "threadId = %@ AND NOT (ANY labels.id IN %@)", email.threadId, rejectedLabels)
        })
        return threads
    }
    
    class func getThreads(since date:Date, searchParam: String, limit: Int = PAGINATION_SIZE, threadIds: [String] = []) -> [Thread] {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.all.rejectedLabelIds
        let emails = realm.objects(Email.self).filter("NOT (ANY labels.id IN %@) AND (ANY emailContacts.contact.displayName contains[cd] %@ OR preview contains[cd] %@ OR subject contains[cd] %@)", rejectedLabels, searchParam, searchParam, searchParam).sorted(byKeyPath: "date", ascending: false).distinct(by: ["threadId"]).filter("date < %@", date)
        return customDistinctEmailThreads(emails: emails, label: SystemLabel.all.id, limit: limit, date: date, emailFilter: { (email) -> NSPredicate in
            return NSPredicate(format: "threadId = %@ AND NOT (ANY labels.id IN %@)", email.threadId, rejectedLabels)
        })
    }
    
    class func getUnreadThreads(from label:Int, since date:Date, limit: Int = PAGINATION_SIZE, threadIds: [String] = []) -> [Thread] {
        let emailsLimit = limit == 0 ? PAGINATION_SIZE : limit
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.all.rejectedLabelIds
        let predicate = NSPredicate(format: "NOT (ANY labels.id IN %@)", rejectedLabels)
        let emails = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: false).distinct(by: ["threadId"]).filter("date < %@", date)
        let threads = customDistinctEmailThreads(emails: emails, label: label, limit: emailsLimit, date: date, emailFilter: { (email) -> NSPredicate in
            guard label != SystemLabel.trash.id && label != SystemLabel.spam.id && label != SystemLabel.draft.id else {
                return NSPredicate(format: "ANY labels.id = %d AND threadId = %@ AND unread = true", label, email.threadId)
            }
            return NSPredicate(format: "threadId = %@ AND NOT (ANY labels.id IN %@) AND unread = true", email.threadId, rejectedLabels)
        })
        return threads
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
            guard !threadIds.contains(email.threadId) else {
                continue
            }
            let threadEmails = realm.objects(Email.self).filter(emailFilter(email)).sorted(byKeyPath: "date", ascending: true)
            guard !threadEmails.isEmpty,
                label == SystemLabel.all.id || !threadEmails.filter(NSPredicate(format: "ANY labels.id = %d", label)).isEmpty else {
                continue
            }
            thread.unread = threadEmails.contains(where: {$0.unread})
            thread.counter = threadEmails.count
            thread.subject = threadEmails.first!.subject
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
        thread.date = thread.lastEmail.date
        thread.threadId = thread.lastEmail.threadId
        thread.unread = threadEmails.contains(where: {$0.unread})
        thread.subject = threadEmails.first!.subject
        thread.counter = threadEmails.count
        return thread
    }
    
    class func getThreadEmails(_ threadId: String, label: Int) -> Results<Email> {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? []
        let predicate1 = NSPredicate(format: "threadId == %@ AND NOT (ANY labels.id IN %@)", threadId, rejectedLabels)
        let predicate2 = NSPredicate(format: "ANY labels.id = %d AND threadId = %@", label, threadId)
        let predicate = (label == SystemLabel.trash.id || label == SystemLabel.spam.id || label == SystemLabel.draft.id) ? predicate2 : predicate1
        let results = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: true)
        
        return results
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
    
    class func updateEmails(_ emailKeys: [Int], unread: Bool) {
        let realm = try! Realm()
        
        try! realm.write() {
            for key in emailKeys {
                let email = realm.object(ofType: Email.self, forPrimaryKey: key)
                email?.unread = unread
            }
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
        
        try? realm.write {
            self.deleteEmail(realm: realm, emails: [email])
        }
    }
    
    class func delete(_ emails:[Email]){
        let realm = try! Realm()
        
        try? realm.write {
            self.deleteEmail(realm: realm, emails: emails)
        }
    }
    
    class func deleteThreads(_ threadId: String, label: Int){
        let emails = Array(getThreadEmails(threadId, label: label))
        let realm = try! Realm()
        
        try! realm.write {
            self.deleteEmail(realm: realm, emails: emails)
        }
    }
    
    class func getTrashThreads(from date: Date) -> [String]? {
        let realm = try! Realm()
        var threadIds: [String]?
        try! realm.write {
            let emails = Array(realm.objects(Email.self).filter("ANY labels.id IN %@ AND trashDate < %@", [SystemLabel.trash.id], date))
            threadIds = Array(Set(emails.map({ (email) -> String in
                return email.threadId
            })))
        }
        return threadIds
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
                file.fileKey = ""
            })
        }
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
    
    class func getLabels() -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self))
    }
    
    class func getLabels(notIn ids: [Int]) -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self).filter(NSPredicate(format: "NOT (id IN %@)", ids)))
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
    
    class func getMoveableLabels(label: Int) -> [Label] {
        let moveableLabels = (SystemLabel.init(rawValue: label) ?? .starred).moveableLabels
        return moveableLabels.map({ (label) -> Label in
            return getLabel(label.id)!
        })
    }
    
    class func getSettableLabels() -> [Label] {
        var settableLabels = getActiveCustomLabels()
        settableLabels.append(getLabel(SystemLabel.starred.id)!)
        return settableLabels
    }
    
    //MARK: - File
    
    class func delete(_ files: [File]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(files)
        }
    }

    //MARK: - Feed
    
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
    
    //MARK: - Email Contact
    
    class func getEmailContacts() -> [EmailContact] {
        let realm = try! Realm()
        
        return Array(realm.objects(EmailContact.self))
    }

    //MARK: - Peer Events
    
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
        let wasInTrash = email.isTrash
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
        if (!wasInTrash && email.isTrash) {
            email.trashDate = Date()
        } else if (wasInTrash && !email.isTrash) {
            email.trashDate = nil
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

    //MARK: - QueueItem
    
    @discardableResult class func createQueueItem(params: [String: Any]) -> QueueItem {
        let realm = try! Realm()
        let queueItem = QueueItem()
        queueItem.params = params
        
        try! realm.write {
            realm.add(queueItem)
        }
        return queueItem
    }
    
    class func getQueueItems() -> Results<QueueItem> {
        let realm = try! Realm()
        return realm.objects(QueueItem.self).sorted(byKeyPath: "date", ascending: true)
    }
    
    class func deleteQueueItems(_ queueItems: [QueueItem]) {
        let realm = try! Realm()
        
        try! realm.write() {
            realm.delete(queueItems)
        }
    }
}
