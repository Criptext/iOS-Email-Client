//
//  CriptextSignedPreKeyStore.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class CriptextSignedPreKeyStore: NSObject, SignedPreKeyStore{
    
    func loadSignedPrekey(_ signedPreKeyId: Int32) -> SignedPreKeyRecord {
        guard let signedPreKeyRecords = DBManager.getSignedKeyRecordById(id: signedPreKeyId) else {
            return SignedPreKeyRecord()
        }
        let signedPreKeyRecordsData = Data(base64Encoded: signedPreKeyRecords.signedPreKeyPair)
        return NSKeyedUnarchiver.unarchiveObject(with: signedPreKeyRecordsData!) as! SignedPreKeyRecord
    }
    
    func loadSignedPrekeyOrNil(_ signedPreKeyId: Int32) -> SignedPreKeyRecord? {
        guard let signedPreKeyRecords = DBManager.getSignedKeyRecordById(id: signedPreKeyId) else {
            return nil
        }
        let signedPreKeyRecordsData = Data(base64Encoded: signedPreKeyRecords.signedPreKeyPair)
        return NSKeyedUnarchiver.unarchiveObject(with: signedPreKeyRecordsData!) as? SignedPreKeyRecord
    }
    
    func loadSignedPreKeys() -> [SignedPreKeyRecord] {
        var mySignedPreKeyRecords = [SignedPreKeyRecord]()
        for record in DBManager.getAllSignedKeyRecords() {
            let signedPreKeyRecordsData = Data(base64Encoded: record.signedPreKeyPair)
            let keyRecord = NSKeyedUnarchiver.unarchiveObject(with: signedPreKeyRecordsData!) as! SignedPreKeyRecord
            mySignedPreKeyRecords.append(keyRecord)
        }
        return mySignedPreKeyRecords
    }
    
    func storeSignedPreKey(_ signedPreKeyId: Int32, signedPreKeyRecord: SignedPreKeyRecord) {
        let keyData = NSKeyedArchiver.archivedData(withRootObject: signedPreKeyRecord)
        let keyString = keyData.base64EncodedString()
        let keyRecord = SignedKeyRecord()
        keyRecord.signedPreKeyId = Int(signedPreKeyId)
        keyRecord.signedPreKeyPair = keyString
        DBManager.store(keyRecord)
    }
    
    func containsSignedPreKey(_ signedPreKeyId: Int32) -> Bool {
        guard DBManager.getSignedKeyRecordById(id: signedPreKeyId) != nil else {
            return false
        }
        return true
    }
    
    func removeSignedPreKey(_ signedPrekeyId: Int32) {
        DBManager.deleteSignedKeyRecord(id: signedPrekeyId)
    }
}
