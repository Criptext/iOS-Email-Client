//
//  CriptextSessionStore.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class CriptextSessionStore: NSObject{
    let account: Account
    
    init(account: Account) {
        self.account = account
        super.init()
    }
}

extension CriptextSessionStore: SessionStore{
    func loadSession(_ contactIdentifier: String!, deviceId: Int32) -> SessionRecord! {
        guard let rawSessionRecord = DBAxolotl.getSessionRecord(contactId: contactIdentifier, deviceId: deviceId, account: account),
            let sessionData = Data(base64Encoded: rawSessionRecord.sessionRecord),
            let sessionRecord = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as? SessionRecord else {
            return SessionRecord()
        }
        return sessionRecord
    }
    
    func subDevicesSessions(_ contactIdentifier: String!) -> [Any]! {
        return [String]()
    }
    
    func storeSession(_ contactIdentifier: String!, deviceId: Int32, session: SessionRecord!) {
        let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
        let sessionString = sessionData.base64EncodedString()
        if let existingSession = DBAxolotl.getSessionRecord(contactId: contactIdentifier, deviceId: deviceId, account: account) {
            DBAxolotl.update(existingSession, sessionString: sessionString)
            return
        }
        let sessionRecord = CRSessionRecord()
        sessionRecord.contactId = contactIdentifier
        sessionRecord.deviceId = deviceId
        sessionRecord.sessionRecord = sessionString
        sessionRecord.account = account
        sessionRecord.buildCompoundKey()
        DBAxolotl.store(sessionRecord)
    }
    
    func containsSession(_ contactIdentifier: String!, deviceId: Int32) -> Bool {
        return DBAxolotl.getSessionRecord(contactId: contactIdentifier, deviceId: deviceId, account: account) != nil
    }
    
    func deleteSession(forContact contactIdentifier: String!, deviceId: Int32) {
        DBAxolotl.deleteSessionRecord(contactId: contactIdentifier, deviceId: deviceId, account: account)
    }
    
    func deleteAllSessions(forContact contactIdentifier: String!) {
        DBAxolotl.deleteAllSessions(contactId: contactIdentifier, account: account)
    }
    
}
