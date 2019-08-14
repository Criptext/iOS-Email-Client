//
//  EventParser.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 5/16/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftSoup

class EventParser {
    let accounts: [Account]
    
    init(accounts: [Account]) {
        self.accounts = accounts
    }
    
    func handleSocketEvent(event: [String: Any]) -> EventData.Socket {
        guard let cmd = event["cmd"] as? Int32 else {
            return .Unhandled
        }
        
        guard let recipientId = event["recipientId"] as? String else {
            return .Unhandled
        }
        
        switch(cmd){
        case Event.Sync.start.rawValue:
            guard let params = event["params"] as? [String: Any],
                let domain = params["domain"] as? String,
                let linkData = LinkData.fromDictionary(params, kind: .sync) else {
                    return .Error
            }
            return .LinkData(linkData, recipientId, domain)
        case Event.Sync.accept.rawValue:
            guard let params = event["params"] as? [String: Any],
                let domain = params["domain"] as? String,
                let syncData = AcceptData.fromDictionary(params) else {
                    return .Error
            }
            return .SyncAccept(syncData, recipientId, domain)
        case Event.Sync.deny.rawValue:
            return .SyncDeny
        case Event.Link.start.rawValue:
            guard let params = event["params"] as? [String: Any],
                let domain = params["domain"] as? String,
                let linkData = LinkData.fromDictionary(params, kind: .link) else {
                    return .Error
            }
            return .LinkData(linkData, recipientId, domain)
        case Event.Peer.passwordChange.rawValue:
            return .PasswordChange
        case Event.Link.removed.rawValue:
            return .Logout
        case Event.Link.bundle.rawValue:
            guard let params = event["params"] as? [String: Any],
                let deviceId = params["deviceId"] as? Int32 else {
                    return .Error
            }
            return .KeyBundle(deviceId)
        case Event.Peer.recoveryChange.rawValue:
            guard let params = event["params"] as? [String: Any],
                let address = params["address"] as? String else {
                    return .Error
            }
            return .RecoveryChanged(address)
        case Event.Peer.recoveryVerify.rawValue:
            return .RecoveryVerified
        case Event.Enterprise.accountSuspended.rawValue:
            guard let params = event["params"] as? [String: Any],
                let domain = params["domain"] as? String else {
                    return .Error
            }
            return .EnterpriseSuspended(recipientId, domain)
        case Event.Enterprise.accountUnsuspended.rawValue:
            guard let params = event["params"] as? [String: Any],
                let domain = params["domain"] as? String else {
                    return .Error
            }
            return .EnterpriseUnSuspended(recipientId, domain)
        case Event.Link.dismiss.rawValue:
            guard let domain = event["domain"] as? String else {
                return .Error
            }
            return .LinkDismiss(recipientId, domain)
        case Event.Sync.dismiss.rawValue:
            guard let domain = event["domain"] as? String else {
                return .Error
            }
            return .SyncDismiss(recipientId, domain)
        case Event.newEvent.rawValue:
            guard let domain = event["domain"] as? String else {
                    return .Error
            }
            return .NewEvent(recipientId, domain)
        default:
            return .Unhandled
        }
    }
}
