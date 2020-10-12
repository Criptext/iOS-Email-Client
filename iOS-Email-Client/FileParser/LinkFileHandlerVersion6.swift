//
//  LinkFileHandlerVersion6.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 5/11/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class LinkFileHandlerVersion6: LinkFileInterface {
    func handleLinkFileRow(realm: Realm, row: [String: Any], maps: inout LinkDBMaps, accountId: String){
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
            if let isNewsletter = object["isNewsletter"] as? Bool {
                email.isNewsletter = isNewsletter ? Email.IsNewsletter.itIs.rawValue : Email.IsNewsletter.isNot.rawValue
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
        case "alias":
            let rowId = object["rowId"] as! Int
            let name = object["name"] as! String
            let active = object["active"] as! Bool
            let domain = object["domain"] as? String
            let alias = Alias()
            alias.account = account
            alias.active = active
            alias.name = name
            alias.domain = domain
            alias.rowId = rowId
            realm.add(alias, update: .all)
        case "customDomain":
            let name = object["name"] as! String
            let validated  = object["validated"] as! Bool
            let customDomain = CustomDomain()
            customDomain.account = account
            customDomain.validated = validated
            customDomain.name = name
            realm.add(customDomain, update: .all)
        default:
            return
        }
    }
}
