//
//  SharedDB.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class SharedDB {
    
    class func getFirstAccount() -> Account? {
        let realm = try! Realm()
        
        return realm.objects(Account.self).first
    }
    
    class func getAccountByUsername(_ username: String) -> Account? {
        let realm = try! Realm()
        
        return realm.object(ofType: Account.self, forPrimaryKey: username)
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
    
    class func store(_ file: File){
        let realm = try! Realm()
        try! realm.write {
            file.id = (realm.objects(File.self).max(ofProperty: "id") as Int? ?? 0) + 1
            realm.add(file, update: true)
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
    
    class func updateEmail(_ email: Email, status: Int){
        let realm = try! Realm()
        
        try! realm.write() {
            email.delivered = status
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
}
