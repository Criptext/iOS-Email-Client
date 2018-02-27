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
        guard let mySessions = sessionRecords[contactIdentifier],
            let mySession = mySessions[deviceId] else {
            return SessionRecord()
        }
        return mySession
    }
    
    func subDevicesSessions(_ contactIdentifier: String!) -> [Any]! {
        return [String]()
    }
    
    func storeSession(_ contactIdentifier: String!, deviceId: Int32, session: SessionRecord!) {
        sessionRecords[contactIdentifier] = [deviceId: session]
    }
    
    func containsSession(_ contactIdentifier: String!, deviceId: Int32) -> Bool {
        guard let mySessions = sessionRecords[contactIdentifier] else {
                return true
        }
        return mySessions[deviceId] != nil
    }
    
    func deleteSession(forContact contactIdentifier: String!, deviceId: Int32) {
        sessionRecords[contactIdentifier] = nil
    }
    
    func deleteAllSessions(forContact contactIdentifier: String!) {
        sessionRecords = [String : [Int32: SessionRecord]]()
    }
    
}
