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
    
    class func getFirstAccount() -> Account? {
        let realm = try! Realm()
        
        return realm.objects(Account.self).first
    }
    
    class func getAccountByUsername(_ username: String) -> Account? {
        let realm = try! Realm()
        
        return realm.object(ofType: Account.self, forPrimaryKey: username)
    }
    
    class func update(_ account: Account, jwt: String) {
        let realm = try! Realm()
        
        try! realm.write {
            account.jwt = jwt
        }
    }
    
    class func update(_ account: Account, refreshToken: String) {
        let realm = try! Realm()
        
        try! realm.write {
            account.refreshToken = refreshToken
        }
    }
    
    @discardableResult class func store(_ email:Email) -> Bool {
        let realm = try! Realm()
        
        do {
            try realm.write() {
                if realm.object(ofType: Email.self, forPrimaryKey: email.key) != nil {
                    return
                }
                realm.add(email, update: false)
            }
            return true
        } catch {
            return false
        }
    }
    
    class func clone(_ email: Email) -> Email {
        let realm = try! Realm()
        var email: Email!
        try! realm.write {
            email = realm.create(Email.self, value: email, update: true)
        }
        return email
    }
    
    class func getUnreadMailsCounter(from label: Int) -> Int {
        let realm = try! Realm()
        let rejectedLabels = SystemLabel.init(rawValue: label)?.rejectedLabelIds ?? []
        return realm.objects(Email.self).filter("ANY labels.id = %@ AND unread = true AND NOT (ANY labels.id IN %@)", label, rejectedLabels).distinct(by: ["threadId"]).count
    }
    
    //MARK: - Contacts related
    
    class func getContacts(_ text:String) -> [Contact]{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "email contains[c] '\(text)' OR displayName contains[c] '\(text)'")
        let results = realm.objects(Contact.self).filter(predicate)
        
        return Array(results)
    }
    
    class func store(_ contacts:[Contact]){
        let realm = try! Realm()
        
        try! realm.write {
            contacts.forEach({ (contact) in
                realm.add(contacts, update: true)
            })
        }
    }
    
    class func update(contact: Contact, name: String){
        let realm = try! Realm()
        try! realm.write {
            contact.displayName = name
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
    
    class func duplicateFiles(key: Int, duplicates: [String: Any]) -> [[String: Any]]? {
        let realm = try! Realm()
        
        guard let email = realm.object(ofType: Email.self, forPrimaryKey: key) else {
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
                let fileparam = ["token": newFile.token,
                                 "name": newFile.name,
                                 "size": newFile.size,
                                 "mimeType": newFile.mimeType] as [String : Any]
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
            if let fileKey = getFileKey(emailId: email.key) {
                fileKey.emailId = key
            }
            
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
            if let fileKey = self.getFileKey(emailId: draft.key){
                realm.delete(fileKey)
            }
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
            let keepLabels = email.labels.reduce(List<Label>(), { (labels, label) -> List<Label> in
                guard label.id == SystemLabel.draft.id || label.id == SystemLabel.sent.id else {
                    return labels
                }
                return labels + [label]
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
    
    class func getLabel(text: String) -> Label?{
        let realm = try! Realm()
        
        return realm.objects(Label.self).filter(NSPredicate(format: "text = %@", text)).first
    }
    
    class func getMailByKey(key: Int) -> Email?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "key == \(key)")
        let results = realm.objects(Email.self).filter(predicate)
        
        return results.first
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
