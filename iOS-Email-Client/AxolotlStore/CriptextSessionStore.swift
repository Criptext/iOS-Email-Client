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
    var sessionRecords = [String : [Int32: SessionRecord]]()
}

extension CriptextSessionStore: SessionStore{
    func loadSession(_ contactIdentifier: String!, deviceId: Int32) -> SessionRecord! {
        guard let rawSessionRecord = DBManager.getSessionRecord(contactId: contactIdentifier, deviceId: deviceId),
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
        let rawSession = CRSessionRecord()
        rawSession.contactId = contactIdentifier
        rawSession.deviceId = deviceId
        rawSession.sessionRecord = sessionString
        DBManager.store(rawSession)
    }
    
    func containsSession(_ contactIdentifier: String!, deviceId: Int32) -> Bool {
        return DBManager.getSessionRecord(contactId: contactIdentifier, deviceId: deviceId) != nil
    }
    
    func deleteSession(forContact contactIdentifier: String!, deviceId: Int32) {
        DBManager.deleteSessionRecord(contactId: contactIdentifier, deviceId: deviceId)
    }
    
    func deleteAllSessions(forContact contactIdentifier: String!) {
        DBManager.deleteAllSessions(contactId: contactIdentifier)
    }
    
}
