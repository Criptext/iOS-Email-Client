//
//  CriptextSessionStore.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class CriptextSessionStore: NSObject, SessionStore{
    
    var sessionRecords = [String : [Int32: SessionRecord]]()
    
    func loadSession(_ contactIdentifier: String!, deviceId: Int32) -> SessionRecord! {
        guard sessionRecords[contactIdentifier] != nil && sessionRecords[contactIdentifier]![deviceId] != nil else {
            return SessionRecord()
        }
        return sessionRecords[contactIdentifier]![deviceId]!
    }
    
    func subDevicesSessions(_ contactIdentifier: String!) -> [Any]! {
        return [String]()
    }
    
    func storeSession(_ contactIdentifier: String!, deviceId: Int32, session: SessionRecord!) {
        sessionRecords[contactIdentifier] = [deviceId: session]
    }
    
    func containsSession(_ contactIdentifier: String!, deviceId: Int32) -> Bool {
        guard sessionRecords[contactIdentifier] != nil && sessionRecords[contactIdentifier]![deviceId] != nil else {
            return false
        }
        return true
    }
    
    func deleteSession(forContact contactIdentifier: String!, deviceId: Int32) {
        sessionRecords[contactIdentifier] = nil
    }
    
    func deleteAllSessions(forContact contactIdentifier: String!) {
        sessionRecords = [String : [Int32: SessionRecord]]()
    }
    
}
