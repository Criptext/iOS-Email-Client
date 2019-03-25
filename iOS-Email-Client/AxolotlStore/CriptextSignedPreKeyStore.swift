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
    
    let account: Account
    
    init(account: Account) {
        self.account = account
        super.init()
    }
    
    func loadSignedPrekey(_ signedPreKeyId: Int32) -> SignedPreKeyRecord {
        guard let signedPreKeyRecord = loadSignedPrekeyOrNil(signedPreKeyId) else {
            return SignedPreKeyRecord()
        }
        return signedPreKeyRecord
    }
    
    func loadSignedPrekeyOrNil(_ signedPreKeyId: Int32) -> SignedPreKeyRecord? {
        guard let signedKeyRecord = DBAxolotl.getSignedKeyRecordById(id: signedPreKeyId, account: account),
            let signedPreKeyRecordData = Data(base64Encoded: signedKeyRecord.signedPreKeyPair),
            let signedPreKeyRecord = NSKeyedUnarchiver.unarchiveObject(with: signedPreKeyRecordData) as? SignedPreKeyRecord
        else {
                return nil
        }
        return signedPreKeyRecord
    }
    
    func loadSignedPreKeys() -> [SignedPreKeyRecord] {
        var mySignedPreKeyRecords = [SignedPreKeyRecord]()
        for record in DBAxolotl.getAllSignedKeyRecords(account: account) {
            guard let signedPreKeyRecordsData = Data(base64Encoded: record.signedPreKeyPair),
                let signedPreKeyRecord = NSKeyedUnarchiver.unarchiveObject(with: signedPreKeyRecordsData) as? SignedPreKeyRecord
            else {
                continue
            }
            mySignedPreKeyRecords.append(signedPreKeyRecord)
        }
        return mySignedPreKeyRecords
    }
    
    func storeSignedPreKey(_ signedPreKeyId: Int32, signedPreKeyRecord: SignedPreKeyRecord) {
        let keyData = NSKeyedArchiver.archivedData(withRootObject: signedPreKeyRecord)
        let keyString = keyData.base64EncodedString()
        let keyRecord = CRSignedPreKeyRecord()
        keyRecord.signedPreKeyId = signedPreKeyId
        keyRecord.signedPreKeyPair = keyString
        keyRecord.account = self.account
        keyRecord.buildCompoundKey()
        DBAxolotl.store(keyRecord)
    }
    
    func containsSignedPreKey(_ signedPreKeyId: Int32) -> Bool {
        return DBAxolotl.getSignedKeyRecordById(id: signedPreKeyId, account: account) != nil
    }
    
    func removeSignedPreKey(_ signedPrekeyId: Int32) {
        DBAxolotl.deleteSignedKeyRecord(id: signedPrekeyId, account: account)
    }
}
