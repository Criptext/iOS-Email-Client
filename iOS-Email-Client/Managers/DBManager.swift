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
    
    class func signout(account: Account){
        let realm = try! Realm()
        
        guard !account.isInvalidated else {
            return
        }
        
        try! realm.write {
            account.isLoggedIn = false
            account.isActive = false
            realm.delete(realm.objects(CRSignedPreKeyRecord.self).filter("account.compoundKey == '\(account.compoundKey)'"))
            realm.delete(realm.objects(CRPreKeyRecord.self).filter("account.compoundKey == '\(account.compoundKey)'"))
            realm.delete(realm.objects(CRSessionRecord.self).filter("account.compoundKey == '\(account.compoundKey)'"))
            realm.delete(realm.objects(CRTrustedDevice.self).filter("account.compoundKey == '\(account.compoundKey)'"))
        }
    }
    
    class func clearMailbox(account: Account){
        let realm = try! Realm()
        
        try! realm.write {
            let emails = realm.objects(Email.self).filter("account.compoundKey == '\(account.compoundKey)'")
            for email in emails {
                realm.delete(email.files)
                realm.delete(realm.objects(DummySession.self).filter("key == \(email.key)"))
            }
            realm.delete(emails)
            realm.delete(realm.objects(FeedItem.self).filter("email.account.compoundKey == '\(account.compoundKey)'"))
            realm.delete(realm.objects(EmailContact.self).filter("email.account.compoundKey == '\(account.compoundKey)'"))
            realm.delete(realm.objects(Label.self).filter("account.compoundKey == '\(account.compoundKey)'"))
            realm.delete(realm.objects(QueueItem.self).filter("account.compoundKey == '\(account.compoundKey)'"))
        }
    }
    
    class func destroy(){
        let realm = try! Realm()
        
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    class func getAllPreKeys() -> [CRPreKeyRecord] {
        let realm = try! Realm()
        
        return Array(realm.objects(CRPreKeyRecord.self))
    }
    
    class func deleteEmptyFeeds() {
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(realm.objects(FeedItem.self).filter("contact == nil"))
        }
    }
    
    class func getInactiveAccounts() -> Results<Account> {
        let realm = try! Realm()
        return realm.objects(Account.self).filter("isActive == false AND isLoggedIn == true")
    }
    
    class func getLoggedOutAccount(accountId: String) -> Account? {
        let realm = try! Realm()
        let results = realm.objects(Account.self).filter("isLoggedIn == false AND compoundKey == '\(accountId)'")
        return results.first
    }
    
    class func getLoggedOutAccounts() -> Results<Account> {
        let realm = try! Realm()
        return realm.objects(Account.self).filter("isLoggedIn == false")
    }
    
    class func delete(account: Account){
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(account)
        }
    }
    
    class func createSystemLabels(){
        for systemLabel in SystemLabel.array {
            let newLabel = Label(systemLabel.nameId)
            newLabel.id = systemLabel.id
            newLabel.color = systemLabel.hexColor
            newLabel.type = "system"
            DBManager.store(newLabel)
        }
    }
    
    class func retrieveWholeDB(account: Account) -> LinkDBSource {
        let realm = try! Realm()
        let contacts = realm.objects(Contact.self)
        let labels = realm.objects(Label.self).filter("type == 'custom' AND account.compoundKey == '\(account.compoundKey)'")
        let emails = realm.objects(Email.self).filter("messageId != '' AND account.compoundKey == '\(account.compoundKey)'")
        let emailContacts = realm.objects(EmailContact.self).filter("email.account.compoundKey == '\(account.compoundKey)' AND email.delivered != \(Email.Status.sending.rawValue) AND email.delivered != \(Email.Status.fail.rawValue) AND NOT (ANY email.labels.id == \(SystemLabel.draft.id))")
        let total = contacts.count + labels.count + 3 * emails.count + emailContacts.count
        let step = total * 5 / 100
        return LinkDBSource(contacts: contacts, labels: labels, emails: emails, emailContacts: emailContacts, total: total, step: step)
    }
    
    struct LinkDBSource {
        let contacts: Results<Contact>
        let labels: Results<Label>
        let emails: Results<Email>
        let emailContacts: Results<EmailContact>
        let total: Int
        let step: Int
    }
    
    struct LinkDBMaps {
        var emails: [Int: Int]
        var contacts: [Int: String]
    }
    
    class func insertBatchRows(rows: [[String: Any]], maps: inout LinkDBMaps, accountId: String){
        let realm = try! Realm()
        try! realm.write {
            for row in rows {
                self.insertRow(realm: realm, row: row, maps: &maps, accountId: accountId)
            }
        }
    }
    
    class func insertRow(realm: Realm, row: [String: Any], maps: inout LinkDBMaps, accountId: String){
        guard let account = realm.object(ofType: Account.self, forPrimaryKey: accountId),
            let table = row["table"] as? String,
            let object = row["object"] as? [String: Any] else {
                return
        }
        switch(table){
        case "contact":
            let contact = Contact()
            let contactId = object["id"] as! Int
            contact.email = object["email"] as! String
            contact.displayName = object["name"] as? String ?? (contact.email.contains("@") ? String(contact.email.split(separator: "@").first!) : "Unknown")
            if let isTrusted = object["isTrusted"]{
                contact.isTrusted = isTrusted as! Bool
            }
            if let spamScore = object["spamScore"]{
                contact.spamScore = spamScore as! Int
            }
            realm.add(contact, update: .all)
            maps.contacts[contactId] = contact.email
        case "label":
            let label = Label()
            label.id = object["id"] as! Int
            label.visible = object["visible"] as! Bool
            label.color = object["color"] as! String
            label.text = object["text"] as! String
            label.account = account
            if let uuid = object["uuid"]{
                label.uuid = uuid as! String
            }
            realm.add(label, update: .all)
        case "email":
            let id = object["id"] as! Int
            let email = Email()
            let key = object["key"] as! Int
            FileUtils.saveEmailToFile(email: account.email, metadataKey: "\(key)", body: object["content"] as! String, headers: object["headers"] as? String)
            email.account = account
            email.messageId = (object["messageId"] as? Int)?.description ?? object["messageId"] as! String
            email.threadId = object["threadId"] as! String
            email.unread = object["unread"] as! Bool
            email.secure = object["secure"] as! Bool
            email.preview = object["preview"] as! String
            email.delivered = object["status"] as! Int
            email.key = key
            email.subject = object["subject"] as? String ?? ""
            email.date = EventData.convertToDate(dateString: object["date"] as! String)
            if let unsentDate = object["unsentDate"] as? String {
                email.unsentDate = EventData.convertToDate(dateString: unsentDate)
            }
            if let trashDate = object["trashDate"] as? String {
                email.trashDate = EventData.convertToDate(dateString: trashDate)
            }
            if let from = object["fromAddress"]{
                email.fromAddress = from as! String
            }else{
                email.fromAddress = "\(email.fromContact.displayName) <\(email.fromContact.email)>"
            }
            if let replyTo = object["replyTo"]{
                email.replyTo = replyTo as! String
            }
            if let boundary = object["boundary"]{
                email.boundary = boundary as! String
            }
            email.buildCompoundKey()
            realm.add(email, update: .all)
            maps.emails[id] = email.key
        case "email_label":
            let labelId = object["labelId"] as! Int
            let emailId = object["emailId"] as! Int
            guard let emailKey = maps.emails[emailId],
                let email = realm.object(ofType: Email.self, forPrimaryKey: "\(account.compoundKey):\(emailKey)"),
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
                let email = realm.object(ofType: Email.self, forPrimaryKey: "\(account.compoundKey):\(emailKey)") else {
                    return
            }
            let emailContact = EmailContact()
            emailContact.contact = contact
            emailContact.email = email
            emailContact.type = (object["type"] as! String).lowercased()
            emailContact.compoundKey = emailContact.buildCompoundKey()
            realm.add(emailContact, update: .all)
        case "file":
            let emailId = object["emailId"] as! Int
            guard let emailKey = maps.emails[emailId],
                let email = realm.object(ofType: Email.self, forPrimaryKey: "\(account.compoundKey):\(emailKey)") else {
                return
            }
            let file = File()
            file.name = object["name"] as! String
            file.status = object["status"] as! Int
            file.emailId = emailKey
            file.token = object["token"] as! String
            file.size = object["size"] as! Int
            file.mimeType = object["mimeType"] as! String
            file.date = EventData.convertToDate(dateString: object["date"] as! String)
            file.cid = object["cid"] as? String
            let key = object["key"] as? String
            let iv = object["iv"] as? String
            let fileKey = key != nil && iv != nil ? "\(key!):\(iv!)" : ""
            file.fileKey = fileKey
            realm.add(file, update: .all)
            email.files.append(file)
        default:
            return
        }
    }

    //MARK: - Account related
    
    class func store(_ account: Account){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(account, update: .all)
        }
    }
    
    class func update(account: Account, jwt: String){
        let realm = try! Realm()
        
        try! realm.write() {
            account.jwt = jwt
        }
    }
    
    class func update(account: Account, jwt: String, refreshToken: String, regId: Int32, identityB64: String) {
        let realm = try! Realm()
        
        try! realm.write() {
            let accounts = realm.objects(Account.self).filter("isActive == true")
            for activeAccount in accounts {
                activeAccount.isActive = false
            }
            account.jwt = jwt
            account.refreshToken = refreshToken
            account.regId = regId
            account.identityB64 = identityB64
            account.isActive = true
            account.isLoggedIn = true
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
    
    class func update(account: Account, showCriptextFooter: Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            account.showCriptextFooter = showCriptextFooter
        }
    }
    
    class func activateAccount(_ account: Account) {
        let realm = try! Realm()
        
        try! realm.write() {
            account.isActive = true
        }
    }
    
    class func disableAccount(_ account: Account) {
        let realm = try! Realm()
        
        try! realm.write() {
            account.isActive = false
        }
    }
 
    class func swapAccount(current: Account, active: Account) {
        let realm = try! Realm()
        
        try! realm.write() {
            current.isActive = false
            active.isActive = true
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
                if realm.object(ofType: Email.self, forPrimaryKey: email.compoundKey) != nil {
                    return
                }
                realm.add(email, update: update ? .all : .error)
            }
            return true
        } catch {
            return false
        }
    }
    
    class func countMails() -> Int {
        let realm = try! Realm()
        
        return realm.objects(Email.self).count
    }
    
    class func getThreads(from label: Int, since date:Date, limit: Int = PAGINATION_SIZE, threadIds: [String] = [], account: Account) -> [Thread] {
        var threads = [Thread]()
        autoreleasepool {
            let emailsLimit = limit == 0 ? PAGINATION_SIZE : limit
            let realm = try! Realm()
            let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? [SystemLabel.spam.id, SystemLabel.trash.id]
            let predicate = NSPredicate(format: "!(ANY labels.id IN %@) AND account.compoundKey == '\(account.compoundKey)' AND date < %@", rejectedLabels, date as NSDate)
            let emails = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: false).distinct(by: ["threadId"])
            threads = customDistinctEmailThreads(emails: emails, label: label, limit: emailsLimit, threadIds: threadIds, myEmail: account.email, emailFilter: { (email) -> NSPredicate in
                guard label != SystemLabel.trash.id && label != SystemLabel.spam.id && label != SystemLabel.draft.id else {
                    return NSPredicate(format: "!(threadId IN %@) AND ANY labels.id = %d AND threadId = %@ AND account.compoundKey == '\(account.compoundKey)'", threadIds, label, email.threadId)
                }
                return NSPredicate(format: "!(threadId IN %@) AND threadId = %@ AND NOT (ANY labels.id IN %@) AND account.compoundKey == '\(account.compoundKey)'", threadIds, email.threadId, rejectedLabels)
            })
        }
        return threads
    }
    
    class func getThreads(since date:Date, searchParam: String, limit: Int = PAGINATION_SIZE, threadIds: [String] = [], account: Account) -> [Thread] {
        var threads = [Thread]()
        autoreleasepool {
            let realm = try! Realm()
            let rejectedLabels = SystemLabel.all.rejectedLabelIds
            let emails = realm.objects(Email.self).filter("NOT (ANY labels.id IN %@) AND (ANY emailContacts.contact.displayName contains[cd] %@ OR preview contains[cd] %@ OR subject contains[cd] %@ OR fromAddress contains[cd] %@) AND NOT (threadId IN %@) AND account.compoundKey == '\(account.compoundKey)'", rejectedLabels, searchParam, searchParam, searchParam, searchParam, threadIds).sorted(byKeyPath: "date", ascending: false).distinct(by: ["threadId"]).filter("date < %@", date)
            threads = customDistinctEmailThreads(emails: emails, label: SystemLabel.all.id, limit: limit, threadIds: threadIds, myEmail: account.email, emailFilter: { (email) -> NSPredicate in
                return NSPredicate(format: "threadId = %@ AND NOT (ANY labels.id IN %@) AND account.compoundKey == '\(account.compoundKey)'", email.threadId, rejectedLabels)
            })
        }
        return threads
    }
    
    class func getUnreadThreads(from label:Int, since date:Date, limit: Int = PAGINATION_SIZE, threadIds: [String] = [], account: Account) -> [Thread] {
        let emailsLimit = limit == 0 ? PAGINATION_SIZE : limit
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.all.rejectedLabelIds
        let predicate = NSPredicate(format: "NOT (ANY labels.id IN %@) AND account.compoundKey == '\(account.compoundKey)'", rejectedLabels)
        let emails = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: false).distinct(by: ["threadId"]).filter("date < %@", date)
        let threads = customDistinctEmailThreads(emails: emails, label: label, limit: emailsLimit, threadIds: threadIds, myEmail: account.email, emailFilter: { (email) -> NSPredicate in
            guard label != SystemLabel.trash.id && label != SystemLabel.spam.id && label != SystemLabel.draft.id else {
                return NSPredicate(format: "ANY labels.id = %d AND threadId = %@ AND unread = true AND account.compoundKey == '\(account.compoundKey)'", label, email.threadId)
            }
            return NSPredicate(format: "threadId = %@ AND NOT (ANY labels.id IN %@) AND unread = true AND account.compoundKey == '\(account.compoundKey)'", email.threadId, rejectedLabels)
        })
        return threads
    }
    
    private class func customDistinctEmailThreads(emails: Results<Email>, label: Int, limit: Int, threadIds: [String] = [], myEmail: String, emailFilter: (Email) -> NSPredicate) -> [Thread] {
        let realm = try! Realm()
        var threads = [Thread]()
        var myThreadIds = Set<String>(threadIds)
        for email in emails {
            guard threads.count < limit else {
                break
            }
            guard !myThreadIds.contains(email.threadId) else {
                continue
            }
            let threadEmails = realm.objects(Email.self).filter(emailFilter(email)).sorted(byKeyPath: "date", ascending: true)
            guard !threadEmails.isEmpty,
                label == SystemLabel.all.id || !threadEmails.filter(NSPredicate(format: "ANY labels.id = %d", label)).isEmpty else {
                continue
            }
            let thread = Thread()
            thread.fromLastEmail(lastEmail: email, threadEmails: threadEmails, label: label, myEmail: myEmail)
            myThreadIds.insert(thread.threadId)
            threads.append(thread)
        }
        return threads
    }
    
    public class func getThread(threadId: String, label: Int, account: Account) -> Thread? {
        let thread = Thread()
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? [SystemLabel.spam.id, SystemLabel.trash.id]
        
        let predicate1 = NSPredicate(format: "threadId == %@ AND NOT (ANY labels.id IN %@) AND account.compoundKey == '\(account.compoundKey)'", threadId, rejectedLabels)
        let predicate2 = NSPredicate(format: "ANY labels.id = %d AND threadId = %@ AND account.compoundKey == '\(account.compoundKey)'", label, threadId)
        let mailsPredicate = label != SystemLabel.trash.id && label != SystemLabel.spam.id && label != SystemLabel.draft.id ? predicate1 : predicate2
        let threadEmails = realm.objects(Email.self).filter(mailsPredicate).sorted(byKeyPath: "date", ascending: true)
        guard !threadEmails.isEmpty,
            label == SystemLabel.all.id || !threadEmails.filter(NSPredicate(format: "ANY labels.id = %d", label)).isEmpty else {
            return nil
        }
        thread.fromLastEmail(lastEmail: threadEmails.last!, threadEmails: threadEmails, label: label, myEmail: account.email)
        return thread
    }
    
    class func getThreadEmails(_ threadId: String, label: Int, account: Account) -> Results<Email> {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? []
        let predicate1 = NSPredicate(format: "threadId == %@ AND NOT (ANY labels.id IN %@) AND account.compoundKey == '\(account.compoundKey)'", threadId, rejectedLabels)
        let predicate2 = NSPredicate(format: "ANY labels.id = %d AND threadId = %@ AND account.compoundKey == '\(account.compoundKey)'", label, threadId)
        let predicate = (label == SystemLabel.trash.id || label == SystemLabel.spam.id || label == SystemLabel.draft.id) ? predicate2 : predicate1
        let results = realm.objects(Email.self).filter(predicate).sorted(byKeyPath: "date", ascending: true)
        
        return results
    }
    
    class func getUnreadMails(from label: Int, account: Account) -> [Email] {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? []
        let emails = Array(realm.objects(Email.self).filter("ANY labels.id = %@ AND unread = true AND NOT (ANY labels.id IN %@) AND account.compoundKey == '\(account.compoundKey)'", label, rejectedLabels))
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
    
    class func updateEmails(_ emailKeys: [Int], unread: Bool, account: Account) {
        let realm = try! Realm()
        
        try! realm.write() {
            for key in emailKeys {
                let email = realm.object(ofType: Email.self, forPrimaryKey: "\(account.compoundKey):\(key)")
                email?.unread = unread
            }
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
    
    class func deleteThreads(_ threadId: String, label: Int, account: Account){
        let emails = Array(getThreadEmails(threadId, label: label, account: account))
        let realm = try! Realm()
        
        try! realm.write {
            self.deleteEmail(realm: realm, emails: emails)
        }
    }
    
    class func getTrashThreads(from date: Date, account: Account) -> [String]? {
        let realm = try! Realm()
        let emails = Array(realm.objects(Email.self).filter("ANY labels.id IN %@ AND trashDate < %@ AND account.compoundKey == '\(account.compoundKey)'", [SystemLabel.trash.id], date))
        let threadIds = Array(Set(emails.map({ (email) -> String in
            return email.threadId
        })))
        return threadIds
    }
    
    class func updateThread(threadId: String, currentLabel: Int, unread: Bool, account: Account){
        let emails = getThreadEmails(threadId, label: currentLabel, account: account)
        for email in emails {
            updateEmail(email, unread: unread)
        }
    }
    
    class func getEmailFailed(account: Account) -> Email? {
        var dateComponents = DateComponents()
        dateComponents.setValue(-3, for: .day)
        let yesterday = Calendar.current.date(byAdding: dateComponents, to: Date())
        let realm = try! Realm()
        let hasFailed = NSPredicate(format: "date <= %@ AND delivered == \(Email.Status.fail.rawValue) AND NOT (ANY labels.id IN %@) AND account.compoundKey == '\(account.compoundKey)'", yesterday! as CVarArg, [SystemLabel.trash.id])
        let results = realm.objects(Email.self).filter(hasFailed)
        return results.first
    }
    
    class func unsendEmail(_ email: Email, date: Date = Date()){
        let realm = try! Realm()
        
        try! realm.write() {
            email.content = ""
            email.preview = ""
            email.unsentDate = date
            email.delivered = Email.Status.unsent.rawValue
            
            email.files.forEach({ (file) in
                file.name = ""
                file.size = 0
                file.mimeType = ""
                file.status = 0
                file.fileKey = ""
                file.cid = nil
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
            realm.add(label, update: .all)
        }
    }
    
    class func updateLabel(_ label: Label, visible: Bool){
        let realm = try! Realm()
        try! realm.write {
            label.visible = visible
        }
    }
    
    class func updateLabelName(_ label: Label, newName: String){
        let realm = try! Realm()
        try! realm.write {
            label.text = newName
        }
    }
    
    class func updateLabelNameByUUID(uuid: String, newName: String, account: Account){
        let realm = try! Realm()
        if let label = realm.objects(Label.self).filter(NSPredicate(format: "uuid = '\(uuid)' AND (account.compoundKey = '\(account.compoundKey)' OR account = nil)")).first {
            try! realm.write {
                label.text = newName
            }
        }
    }
    
    class func getLabels(type: String) -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self).filter(NSPredicate(format: "type = %@", type)))
    }
    
    class func getActiveCustomLabels(account: Account) -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self).filter(NSPredicate(format: "account.compoundKey = '\(account.compoundKey)' AND type = 'custom' AND visible = true")))
    }
    
    class func getLabels() -> [Label]{
        let realm = try! Realm()
        
        return Array(realm.objects(Label.self))
    }
    
    class func getUserLabels(account: Account, visible: Bool = true) -> [Label] {
        let realm = try! Realm()
        
        if visible {
            return Array(realm.objects(Label.self).filter(NSPredicate(format: "account.compoundKey = '\(account.compoundKey)' AND visible = true")))
        }
        return Array(realm.objects(Label.self).filter(NSPredicate(format: "account.compoundKey = '\(account.compoundKey)'")))
    }
    
    class func setLabelsForThread(_ threadId: String, labels: [Int], currentLabel: Int, account: Account){
        let emails = getThreadEmails(threadId, label: currentLabel, account: account)
        for email in emails {
            setLabelsForEmail(email, labels: labels)
        }
    }
    
    class func addRemoveLabelsForThreads(_ threadId: String, addedLabelIds: [Int], removedLabelIds: [Int], currentLabel: Int, account: Account){
        let emails = getThreadEmails(threadId, label: currentLabel, account: account)
        for email in emails {
            addRemoveLabelsFromEmail(email, addedLabelIds: addedLabelIds, removedLabelIds: removedLabelIds)
            if(email.fromContact.email != account.email) {
                if(addedLabelIds.contains(SystemLabel.spam.id)){
                    uptickSpamCounter(email.fromContact)
                } else if (removedLabelIds.contains(SystemLabel.spam.id)) {
                    resetSpamCounter(email.fromContact)
                }
            }
        }
    }
    
    class func getMoveableLabels(label: Int) -> [Label] {
        let moveableLabels = (SystemLabel.init(rawValue: label) ?? .starred).moveableLabels
        return moveableLabels.map({ (label) -> Label in
            return getLabel(label.id)!
        })
    }
    
    class func getSettableLabels(account: Account) -> [Label] {
        var settableLabels = getActiveCustomLabels(account: account)
        settableLabels.append(getLabel(SystemLabel.starred.id)!)
        return settableLabels
    }
    
    class func deleteLabel(label: Label){
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(label)
        }
    }
    
    class func deleteLabelByUUID(uuid: String, account: Account){
        let realm = try! Realm()
        if let label = realm.objects(Label.self).filter(NSPredicate(format: "uuid = '\(uuid)' AND (account.compoundKey = '\(account.compoundKey)' OR account = nil)")).first {
            try! realm.write {
                realm.delete(label)
            }
        }
    }
    
    //MARK: - File
    
    class func delete(_ files: [File]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(files)
        }
    }
    
    class func getFile(cid: String) -> File? {
        let realm = try! Realm()
        
        return realm.objects(File.self).filter("cid = %@", cid).first
    }

    //MARK: - Feed
    
    class func store(_ feed: FeedItem){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(feed, update: .all)
        }
    }
    
    class func feedExists(emailId: Int, type: Int, contactId: String) -> Bool {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "contact.email == '\(contactId)' AND email.key == \(emailId) AND type == \(type)")
        let results = realm.objects(FeedItem.self).filter(predicate)
        return results.count > 0
    }
    
    class func getFeeds(since date: Date, limit: Int, lastSeen: Date, account: Account) -> (Results<FeedItem>, Results<FeedItem>){
        let realm = try! Realm()
        
        let newFeeds = realm.objects(FeedItem.self).filter("date > %@ AND email.account.compoundKey == '\(account.compoundKey)'", lastSeen).sorted(byKeyPath: "date", ascending: false)
        let oldFeeds = realm.objects(FeedItem.self).filter("date <= %@ AND email.account.compoundKey == '\(account.compoundKey)'", lastSeen).sorted(byKeyPath: "date", ascending: false)
        
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
                let predicate = NSPredicate(format: "threadId == %@", threadId)
                let emails = realm.objects(Email.self).filter(predicate)
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
                if(addedLabelNames.contains(SystemLabel.spam.nameId)){
                    let predicate = NSPredicate(format: "email == '\(email.fromContact.email)'")
                    let contact = realm.objects(Contact.self).filter(predicate).first
                    if(contact != nil){
                        contact?.spamScore += 1
                    }
                }
                self.addRemoveLabels(realm: realm, email: email, addedLabelNames: addedLabelNames, removedLabelNames: removedLabelNames)
            }
        }
    }
    
    class func addRemoveLabels(threadIds: [String], addedLabelNames: [String], removedLabelNames: [String]){
        let realm = try! Realm()
        
        try! realm.write {
            for threadId in threadIds {
                let predicate = NSPredicate(format: "threadId == %@", threadId)
                let emails = realm.objects(Email.self).filter(predicate)
                for email in emails {
                    if(addedLabelNames.contains(SystemLabel.spam.nameId)){
                        let predicate = NSPredicate(format: "email == '\(email.fromContact.email)'")
                        let contact = realm.objects(Contact.self).filter(predicate).first
                        if(contact != nil){
                            contact?.spamScore += 1
                        }
                    }
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
            guard let index = email.labels.firstIndex(where: {$0.text == labelName}) else {
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
                let predicate = NSPredicate(format: "threadId == %@ AND ANY labels.id IN %@", threadId, deletableLabels)
                let emails = Array(realm.objects(Email.self).filter(predicate))
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

    //MARK: - QueueItem
    
    @discardableResult class func createQueueItem(params: [String: Any], account: Account) -> QueueItem {
        let realm = try! Realm()
        let queueItem = QueueItem()
        queueItem.account = account
        queueItem.params = params
        
        try! realm.write {
            realm.add(queueItem)
        }
        return queueItem
    }
    
    class func getQueueItems(account: Account) -> Results<QueueItem> {
        let realm = try! Realm()
        return realm.objects(QueueItem.self).filter("account.compoundKey == '\(account.compoundKey)'").sorted(byKeyPath: "date", ascending: true)
    }
    
    class func deleteQueueItems(_ queueItems: [QueueItem]) {
        let realm = try! Realm()
        
        try! realm.write() {
            realm.delete(queueItems)
        }
    }
    
    //MARK: - Alias
    
    class func store(_ alias: Alias){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(alias, update: .all)
        }
    }
    
    class func store(aliases: [Alias]){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(aliases, update: .modified)
        }
    }
    
    class func update(alias: Alias, active: Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            alias.active = active
        }
    }
    
    class func deleteAlias(_ alias: Alias) {
        let realm = try! Realm()
        
        try! realm.write() {
            realm.delete(alias)
        }
    }
    
    class func deleteAlias(_ domainName: String?, account: Account) {
        let realm = try! Realm()
        let aliasesToDelete = getAliases(account: account).filter { $0.domainName == domainName }
        
        try! realm.write() {
            realm.delete(aliasesToDelete)
        }
    }
    
    //MARK: - CustomDomain
    
    class func store(_ customDomain: CustomDomain){
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(customDomain, update: .all)
        }
    }
    
    class func update(customDomain: CustomDomain, validated: Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            customDomain.validated = validated
        }
    }
    
    class func getCustomDomains(account: Account) -> Results<CustomDomain> {
        let realm = try! Realm()
        return realm.objects(CustomDomain.self).filter("account.compoundKey == '\(account.compoundKey)'")
    }
    
    class func getCustomDomain(name: String, account: Account) -> CustomDomain? {
        let realm = try! Realm()
        return realm.objects(CustomDomain.self).filter("name == '\(name)' AND account.compoundKey == '\(account.compoundKey)'").first
    }
    
    class func deleteCustomDomain(_ customDomain: CustomDomain) {
        let realm = try! Realm()
        
        try! realm.write() {
            realm.delete(customDomain)
        }
    }
}
