//
//  CriptextPreKeyStore.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class CriptextPreKeyStore: NSObject, PreKeyStore{
    // MARK: - PreKeyStore
    
    func loadPreKey(_ preKeyId: Int32) -> PreKeyRecord! {
        guard let preKeyRecord = DBManager.getKeyRecordById(id: preKeyId) else {
            return PreKeyRecord()
        }
        let preKeyRecordData = Data(base64Encoded: preKeyRecord.preKeyPair)
        return NSKeyedUnarchiver.unarchiveObject(with: preKeyRecordData!) as! PreKeyRecord
    }
    
    func storePreKey(_ preKeyId: Int32, preKeyRecord record: PreKeyRecord!) {
        let keyData = NSKeyedArchiver.archivedData(withRootObject: record)
        let keyString = keyData.base64EncodedString()
        let keyRecord = KeyRecord()
        keyRecord.preKeyId = Int(preKeyId)
        keyRecord.preKeyPair = keyString
        DBManager.store(keyRecord)
    }
    
    func containsPreKey(_ preKeyId: Int32) -> Bool {
        guard DBManager.getKeyRecordById(id: preKeyId) != nil else {
            return false
        }
        return true
    }
    
    func removePreKey(_ preKeyId: Int32) {
        DBManager.deleteKeyRecord(id: preKeyId)
    }
}

