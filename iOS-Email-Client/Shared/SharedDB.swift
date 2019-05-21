//
//  SharedDB.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class SharedDB {
    
    class func refresh(){
        let realm = try! Realm()
        
        realm.refresh()
    }
    
    class func getObject(_ ref:ThreadSafeReference<Object>) -> Object? {
        let realm = try! Realm()
        
        return realm.resolve(ref)
    }
    
    class func getReference(_ obj:Object) -> ThreadSafeReference<Object> {
        return ThreadSafeReference(to: obj)
    }
    
    class func getAccount(token: String) -> Account? {
        let realm = try! Realm()
        
        return realm.objects(Account.self).filter("jwt == '\(token)'").first
    }
    
    class func getFirstAccount() -> Account? {
        let realm = try! Realm()
        
        return realm.objects(Account.self).first
    }
    
    class func getAccountByUsername(_ username: String) -> Account? {
        let realm = try? Realm()
        
        return realm?.object(ofType: Account.self, forPrimaryKey: username)
    }
    
    class func getAccounts(ignore username: String) -> Results<Account> {
        let realm = try! Realm()
        return realm.objects(Account.self).filter("isLoggedIn == true AND username != '\(username)'")
    }
    
    class func getAllAccounts() -> [Account] {
        let realm = try? Realm()
        
        return Array(realm!.objects(Account.self))
    }
    
    class func update(oldJwt: String, jwt: String) {
        let realm = try! Realm()
        
        try! realm.write {
            let account = realm.objects(Account.self).filter("jwt == '\(oldJwt)'").first
            account?.jwt = jwt
        }
    }
    
    class func update(oldJwt: String, refreshToken: String, jwt: String) {
        let realm = try! Realm()
        
        try! realm.write {
            let account = realm.objects(Account.self).filter("jwt == '\(oldJwt)'").first
            account?.refreshToken = refreshToken
            account?.jwt = jwt
        }
    }
    
    class func update(account: Account, hasCloudBackup: Bool) {
        let realm = try! Realm()
        
        try! realm.write {
            account.hasCloudBackup = hasCloudBackup
        }
    }
    
    class func update(account: Account, wifiOnly: Bool) {
        let realm = try! Realm()
        
        try! realm.write {
            account.wifiOnly = wifiOnly
        }
    }
    
    class func update(account: Account, frequency: String) {
        let realm = try! Realm()
        
        try! realm.write {
            account.autoBackupFrequency = frequency
        }
    }
    
    class func update(account: Account, lastBackup: Date) {
        let realm = try! Realm()
        
        try! realm.write {
            account.lastTimeBackup = lastBackup
        }
    }
    
    class func update(username: String, lastBackup: Date) {
        let realm = try! Realm()
        
        try! realm.write {
            guard let account = realm.objects(Account.self).filter("username == '\(username)'").first else {
                return
            }
            account.lastTimeBackup = lastBackup
        }
    }
    
    @discardableResult class func store(_ email:Email) -> Bool {
        let realm = try! Realm()
        
        do {
            try realm.write() {
                if realm.object(ofType: Email.self, forPrimaryKey: email.compoundKey) != nil {
                    return
                }
                realm.add(email, update: false)
            }
            return true
        } catch {
            return false
        }
    }
    
    class func getEmail(messageId: String, account: Account) -> Email? {
        let realm = try! Realm()
        
        return realm.objects(Email.self).filter("messageId == '\(messageId)' AND account.compoundKey == '\(account.compoundKey)'").first
    }
    
    class func clone(_ email: Email) -> Email {
        let realm = try! Realm()
        var email: Email!
        try! realm.write {
            email = realm.create(Email.self, value: email, update: true)
        }
        return email
    }
    
    class func hasEmails(account: Account) -> Bool {
        let realm = try! Realm()
        return realm.objects(Email.self).filter("account.compoundKey == '\(account.compoundKey)'").count > 0
    }
    
    class func getUnreadMailsCounter(from label: Int, account: Account) -> Int {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? []
        return realm.objects(Email.self).filter("ANY labels.id = %@ AND unread = true AND NOT (ANY labels.id IN %@) AND account.compoundKey == '\(account.compoundKey)'", label, rejectedLabels).distinct(by: ["threadId"]).count
    }
    
    class func getUnreadCounters() -> Int {
        let realm = try! Realm()
        var counter = 0
        let accounts = realm.objects(Account.self).filter("isLoggedIn == true")
        let rejectedLabels = SystemLabel.inbox.rejectedLabelIds
        for account in accounts {
            counter += realm.objects(Email.self).filter("ANY labels.id = %@ AND unread = true AND NOT (ANY labels.id IN %@) AND account.compoundKey == '\(account.compoundKey)'", SystemLabel.inbox.id, rejectedLabels).distinct(by: ["threadId"]).count
        }
        return counter
    }
    
    //MARK: - Contacts related
    
    class func getContacts(_ text:String, account: Account) -> [Contact]{
        let realm = try! Realm()
        
        let MAX_ADDRESS_LENGTH = 320
        let query = text.count > 320 ? String(text.prefix(MAX_ADDRESS_LENGTH)) : text
        
        let predicate = NSPredicate(format: "(ANY accountContacts.account.compoundKey == '\(account.compoundKey)') AND email contains[c] '\(query)' OR displayName contains[c] '\(text)'")
        let results = realm.objects(Contact.self).filter(predicate).sorted(byKeyPath: "score", ascending: false)
        
        return Array(results)
    }
    
    class func store(_ contacts:[Contact], account: Account){
        let realm = try! Realm()
        
        try! realm.write {
            contacts.forEach({ (contact) in
                realm.add(contacts, update: true)
                let accountContact = AccountContact()
                accountContact.account = account
                accountContact.contact = contact
                accountContact.buildCompoundKey()
                realm.add(accountContact, update: true)
            })
        }
    }
    
    class func update(contact: Contact, name: String){
        let realm = try! Realm()
        try! realm.write {
            contact.displayName = name
        }
    }
    
    class func updateScore(contact: Contact){
        do {
            let realm = try Realm()
            try realm.write {
                contact.score = contact.score + 1
            }
        } catch {
            
        }
    }
    
    class func getContact(_ email:String) -> Contact?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "email == '\(email)'")
        let results = realm.objects(Contact.self).filter(predicate)
        
        return results.first
    }
    
    class func store(_ emailContacts:[EmailContact]){
        let realm = try! Realm()
        
        try! realm.write {
            for emailContact in emailContacts {
                realm.add(emailContact, update: true)
            }
        }
    }
    
    class func getEmailContacts(emailKey: Int) -> [EmailContact] {
        let realm = try! Realm()
        
        return Array(realm.objects(EmailContact.self).filter("email.key == \(emailKey)"))
    }
    
    class func store(_ file: File){
        let realm = try! Realm()
        try! realm.write {
            realm.add(file, update: true)
        }
    }
    
    class func store(_ files: [File]){
        let realm = try! Realm()
        
        try! realm.write {
            files.forEach({ (file) in
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
    
    class func duplicateFiles(account: Account, key: Int, duplicates: [String: Any]) -> [[String: Any]]? {
        let realm = try! Realm()
        
        guard let email = realm.object(ofType: Email.self, forPrimaryKey: "\(account.compoundKey):\(key)") else {
            return nil
        }
        
        var fileParams = [[String: Any]]()
        try! realm.write {
            for (originalToken, newToken) in duplicates {
                guard let token = newToken as? String,
                    let fileIndex = email.files.firstIndex(where: {$0.originalToken == originalToken}) else {
                        continue
                }
                let file = email.files[fileIndex]
                let newFile = file.duplicate()
                newFile.shouldDuplicate = false
                newFile.token = token
                realm.add(newFile, update: true)
                email.files.remove(at: fileIndex)
                realm.delete(file)
                email.files.append(newFile)
                var fileparam = ["token": newFile.token,
                                 "name": newFile.name,
                                 "size": newFile.size,
                                 "mimeType": newFile.mimeType] as [String : Any]
                if let cid = newFile.cid {
                    fileparam["cid"] = cid
                }
                fileParams.append(fileparam)
            }
        }
        return fileParams
    }
    
    class func updateEmail(_ email: Email, status: Int){
        let realm = try! Realm()
        
        try! realm.write() {
            email.delivered = status
        }
    }
    
    class func updateEmail(_ email: Email, key: Int, messageId: String, threadId: String) {
        let realm = try! Realm()
        try! realm.write() {
            let newEmail = Email()
            newEmail.key = key
            newEmail.messageId = messageId
            newEmail.threadId = threadId
            newEmail.delivered = Email.Status.sent.rawValue
            newEmail.unread = false
            newEmail.secure = email.secure
            newEmail.subject = email.subject
            newEmail.content = email.content
            newEmail.preview = email.preview
            newEmail.date = email.date
            newEmail.unsentDate = email.unsentDate
            newEmail.isMuted = email.isMuted
            newEmail.labels.append(objectsIn: email.labels)
            newEmail.files.append(objectsIn: email.files)
            newEmail.fromAddress = email.fromAddress
            newEmail.replyTo = email.replyTo
            newEmail.boundary = email.boundary
            newEmail.account = email.account
            newEmail.buildCompoundKey()
            
            realm.add(newEmail)
            
            let emailContacts = getEmailContacts(emailKey: email.key)
            for emailContact in emailContacts {
                emailContact.email = newEmail
                if(emailContact.type != ContactType.from.rawValue && email.fromContact == emailContact.contact) {
                    newEmail.status = .delivered
                    newEmail.unread = true
                }
            }
            
            realm.delete(email)
        }
    }
    
    class func updateEmail(_ email: Email, status: Email.Status){
        guard email.isSent || email.isDraft else {
            return
        }
        
        let realm = try! Realm()
        
        try! realm.write() {
            email.status = status
        }
    }
    
    class func updateEmail(_ email: Email, unread: Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            email.unread = unread
        }
    }
    
    class func updateEmail(_ email: Email, secure: Bool){
        let realm = try! Realm()
        
        try! realm.write() {
            email.secure = secure
        }
    }
    
    class func deleteDraftInComposer(_ draft: Email){
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(draft.emailContacts)
            realm.delete(draft)
        }
    }
    
    class func addRemoveLabelsFromEmail(_ email: Email, addedLabelIds: [Int], removedLabelIds: [Int]){
        let realm = try! Realm()
        let wasInTrash = email.isTrash
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
            if (!wasInTrash && email.isTrash) {
                email.trashDate = Date()
            } else if (wasInTrash && !email.isTrash) {
                email.trashDate = nil
            }
        }
    }
    
    class func setLabelsForEmail(_ email: Email, labels: [Int]){
        let realm = try! Realm()
        let wasInTrash = email.isTrash
        try! realm.write {
            let keepLabels = email.labels.reduce([Label](), { (labels, label) -> [Label] in
                guard label.id == SystemLabel.draft.id || label.id == SystemLabel.sent.id else {
                    return labels
                }
                return Array(labels) + [label]
            })
            email.labels.removeAll()
            email.trashDate = nil
            email.labels.append(objectsIn: keepLabels)
            for label in labels {
                guard label != SystemLabel.draft.id && label != SystemLabel.sent.id,
                    let labelToAdd = getLabel(label)  else {
                        continue
                }
                email.labels.append(labelToAdd)
            }
            if (!wasInTrash && email.isTrash) {
                email.trashDate = Date()
            } else if (wasInTrash && !email.isTrash) {
                email.trashDate = nil
            }
        }
    }
    
    class func getLabel(_ labelId: Int) -> Label?{
        let realm = try! Realm()
        
        return realm.object(ofType: Label.self, forPrimaryKey: labelId)
    }
    
    class func getUserLabel(_ labelId: Int, account: Account) -> Label?{
        let realm = try! Realm()
        
        return realm.objects(Label.self).filter(NSPredicate(format: "id = \(labelId) AND (account.compoundKey = '\(account.compoundKey)' OR account = nil)")).first
    }
    
    class func getLabel(text: String) -> Label?{
        let realm = try! Realm()
        
        return realm.objects(Label.self).filter(NSPredicate(format: "text = %@", text)).first
    }
    
    class func getMail(key: Int, account: Account) -> Email? {
        let realm = try! Realm()
        return realm.object(ofType: Email.self, forPrimaryKey: "\(account.compoundKey):\(key)")
    }
    
    //MARK: - DummySession
    
    class func store(_ dummySession: DummySession) {
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(dummySession)
        }
    }
    
    class func getDummySession(key: Int) -> DummySession? {
        let realm = try! Realm()
        return realm.object(ofType: DummySession.self, forPrimaryKey: key)
    }
    
    class func deleteDummySession(key: Int) {
        let realm = try! Realm()
        guard let dummySession = realm.object(ofType: DummySession.self, forPrimaryKey: key) else {
            return
        }
        
        try! realm.write() {
            realm.delete(dummySession)
        }
    }
}
