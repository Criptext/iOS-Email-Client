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
        guard let keyRecord = DBAxolotl.getKeyRecordById(id: preKeyId),
            let preKeyRecordData = Data(base64Encoded: keyRecord.preKeyPair),
            let preKeyRecord = NSKeyedUnarchiver.unarchiveObject(with: preKeyRecordData) as? PreKeyRecord
        else {
            return PreKeyRecord()
        }
        return preKeyRecord
    }
    
    func storePreKey(_ preKeyId: Int32, preKeyRecord record: PreKeyRecord!) {
        let keyData = NSKeyedArchiver.archivedData(withRootObject: record)
        let keyString = keyData.base64EncodedString()
        let keyRecord = CRPreKeyRecord()
        keyRecord.preKeyId = preKeyId
        keyRecord.preKeyPair = keyString
        DBAxolotl.store(keyRecord)
    }
    
    func containsPreKey(_ preKeyId: Int32) -> Bool {
        return DBAxolotl.getKeyRecordById(id: preKeyId) != nil
    }
    
    func removePreKey(_ preKeyId: Int32) {
        DBAxolotl.deleteKeyRecord(id: preKeyId)
    }
}

