//
//  RetrieveContactsTask.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/26/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Contacts

class RetrieveContactsTask {
    
    internal struct PhoneContact {
        var email: String
        var name: String
    }
    
    func start(completionHandler: @escaping ((Bool) -> Void)){
        let queue = DispatchQueue(label: "com.criptext.mail.contacts", qos: .background, attributes: .concurrent)
        queue.async {
            self.getContactsFromPhoneBook { (phoneContacts) in
                guard let phContacts = phoneContacts else {
                    DispatchQueue.main.async {
                        completionHandler(false)
                    }
                    return
                }
                self.storeContacts(contacts: phContacts)
                DispatchQueue.main.async {
                    completionHandler(true)
                }
            }
        }
    }
    
    func storeContacts(contacts: [PhoneContact]) {
        for contact in contacts {
            guard DBManager.getContact(contact.email) == nil else {
                continue
            }
            let dbContact = Contact()
            dbContact.displayName = contact.name
            dbContact.email = contact.email
            DBManager.store([dbContact])
        }
    }
    
    func getContactsFromPhoneBook(completion: @escaping (([PhoneContact]?) -> Void)) {
        var myContacts = [PhoneContact]()
        let contactStore = CNContactStore()
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey as CNKeyDescriptor] as [CNKeyDescriptor]
        contactStore.requestAccess(for: .contacts, completionHandler: { (granted, error) in
            guard error == nil,
                granted else {
                completion(nil)
                return
            }
            
            var allContainers: [CNContainer] = []
            do {
                allContainers = try contactStore.containers(matching: nil)
            } catch {
                completion(nil)
                return
            }
            
            for container in allContainers {
                let predicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                var contacts: [CNContact]! = []
                do {
                    contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
                } catch {
                    
                }
                for contact in contacts {
                    print("\(contact.givenName) : \(contact.emailAddresses.description)")
                    guard contact.emailAddresses.count > 0 else {
                        continue
                    }
                    let name = contact.givenName + contact.familyName
                    for email in contact.emailAddresses {
                        let contact = PhoneContact(email: email.value as String, name: name)
                        myContacts.append(contact)
                    }
                }
            }
            completion(myContacts)
        })
    }
}
