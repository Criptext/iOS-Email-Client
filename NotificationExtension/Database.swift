//
//  Database.swift
//  NotificationExtension
//
//  Created by Allisson on 11/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Database {
    
    init() {
        let fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.criptext.team")!.appendingPathComponent("default.realm")
        let config = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: 7)
        Realm.Configuration.defaultConfiguration = config
    }
    
    func getFirstAccount() -> Account? {
        let realm = try! Realm()
        
        return realm.objects(Account.self).first
    }
    
    @discardableResult func store(_ email:Email) -> Bool {
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
    
    func store(_ contacts:[Contact]){
        let realm = try! Realm()
        
        try! realm.write {
            contacts.forEach({ (contact) in
                contact.id = (realm.objects(Contact.self).max(ofProperty: "id") as Int? ?? 0) + 1
                realm.add(contacts, update: true)
            })
        }
    }
    
    func update(contact: Contact, name: String){
        let realm = try! Realm()
        try! realm.write {
            contact.displayName = name
        }
    }
    
    func getContact(_ email:String) -> Contact?{
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "email == '\(email)'")
        let results = realm.objects(Contact.self).filter(predicate)
        
        return results.first
    }
    
    func store(_ emailContacts:[EmailContact]){
        let realm = try! Realm()
        
        try! realm.write {
            for emailContact in emailContacts {
                realm.add(emailContact, update: true)
            }
        }
    }
}
