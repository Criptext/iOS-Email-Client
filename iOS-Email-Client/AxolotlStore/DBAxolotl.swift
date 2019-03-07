//
//  DBAxolotl.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class DBAxolotl {
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
    
    class func getAllKeyRecords(account: Account) -> [CRPreKeyRecord]{
        let realm = try! Realm()
        
        return Array(realm.objects(CRPreKeyRecord.self).filter("account.compoundKey == %@", account.compoundKey))
    }
    
    class func getKeyRecordById(id: Int32, account: Account) -> CRPreKeyRecord?{
        let realm = try! Realm()
        let compoundKey = "\(account.compoundKey):\(id)"
        guard let keyRecord = realm.object(ofType: CRPreKeyRecord.self, forPrimaryKey: compoundKey) else {
            return nil
        }
        return keyRecord
    }
    
    class func deleteKeyRecord(id: Int32, account: Account){
        let realm = try! Realm()
        let compoundKey = "\(account.compoundKey):\(id)"
        guard let keyRecord = realm.object(ofType: CRPreKeyRecord.self, forPrimaryKey: compoundKey) else {
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
    
    class func getSignedKeyRecordById(id: Int32, account: Account) -> CRSignedPreKeyRecord?{
        let realm = try! Realm()
        let compoundKey = "\(account.compoundKey):\(id)"
        guard let keyRecord = realm.object(ofType: CRSignedPreKeyRecord.self, forPrimaryKey: compoundKey) else {
            return nil
        }
        return keyRecord
    }
    
    class func deleteSignedKeyRecord(id: Int32, account: Account){
        let realm = try! Realm()
        let compoundKey = "\(account.compoundKey):\(id)"
        guard let keyRecord = realm.object(ofType: CRSignedPreKeyRecord.self, forPrimaryKey: compoundKey) else {
            return
        }
        try! realm.write() {
            realm.delete(keyRecord)
        }
    }
    
    class func getAllSignedKeyRecords(account: Account) -> [CRSignedPreKeyRecord]{
        let realm = try! Realm()
        
        return Array(realm.objects(CRSignedPreKeyRecord.self).filter("account.compoundKey == '\(account.compoundKey)'"))
    }
    
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
    
    class func getSessionRecord(contactId: String, deviceId: Int32, account: Account) -> CRSessionRecord?{
        let realm = try! Realm()
        let compoundKey = "\(account.compoundKey):\(contactId):\(deviceId)"
        guard let session = realm.object(ofType: CRSessionRecord.self, forPrimaryKey: compoundKey) else {
            return nil
        }
        return session
    }
    
    class func getSessionRecords(recipientId: String, account: Account) -> [CRSessionRecord] {
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "contactId == '\(recipientId)' && account.compoundKey == '\(account.compoundKey)'")
        let results = realm.objects(CRSessionRecord.self).filter(predicate)
        return Array(results)
    }
    
    class func deleteSessionRecord(contactId: String, deviceId: Int32, account: Account){
        let realm = try! Realm()
        
        let compoundKey = "\(account.compoundKey):\(contactId):\(deviceId)"
        guard let session = realm.object(ofType: CRSessionRecord.self, forPrimaryKey: compoundKey) else {
            return
        }
        try! realm.write() {
            realm.delete(session)
        }
    }
    
    class func deleteAllSessions(contactId: String, account: Account){
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "contactId == '\(contactId)' && account.compoundKey == '\(account.compoundKey)'")
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
}
