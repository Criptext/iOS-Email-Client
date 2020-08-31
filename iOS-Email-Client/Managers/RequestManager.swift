//
//  RequestManager.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 3/6/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol RequestDelegate: class {
    func finishRequest(accountId: String, result: EventData.Result)
    func errorRequest(accountId: String, response: ResponseData)
}

final class RequestManager: NSObject {
    static let shared = RequestManager()
    var delegates: [RequestDelegate?] = []
    private var accountRequests = [String]()
    var accountCompletions = [String: ((Bool) -> Void)]()
    private var processingAccount: String? = nil
    
    func getEvents() {
        guard processingAccount == nil,
            let accountId = accountRequests.first else {
                return
        }
        guard let myAccount = DBManager.getAccountById(accountId) else {
            accountRequests.removeFirst()
            return
        }
        processingAccount = accountId
        accountRequests.removeFirst()
        APIManager.getEvents(token: myAccount.jwt) { [weak self] (responseData) in
            guard let myAccount = DBManager.getAccountById(accountId),
                let weakSelf = self,
                weakSelf.processingAccount == accountId else {
                    self?.accountCompletions[accountId] = nil
                    self?.processingAccount = nil
                    self?.getEvents()
                    return
            }
            
            var events = [[String: Any]]()
            var repeatRequest = false
            switch(responseData) {
            case .Removed:
                var result = EventData.Result()
                result.removed = true
                weakSelf.accountCompletions[accountId]?(true)
                weakSelf.accountCompletions[accountId] = nil
                weakSelf.delegates.forEach { delegate in
                    delegate?.finishRequest(accountId: accountId, result: result)
                }
                weakSelf.getEvents()
            case .EnterpriseSuspended:
                var result = EventData.Result()
                result.suspended = true
                weakSelf.accountCompletions[accountId]?(true)
                weakSelf.accountCompletions[accountId] = nil
                weakSelf.delegates.forEach { delegate in
                    delegate?.finishRequest(accountId: accountId, result: result)
                }
                weakSelf.getEvents()
            case .VersionNotSupported:
                var result = EventData.Result()
                result.versionNotSupported = true
                weakSelf.accountCompletions[accountId]?(true)
                weakSelf.accountCompletions[accountId] = nil
                weakSelf.delegates.forEach { delegate in
                    delegate?.finishRequest(accountId: accountId, result: result)
                }
                weakSelf.getEvents()
                break;
            case .SuccessAndRepeat(let responseEvents):
                events = responseEvents
                repeatRequest = true
            case .SuccessArray(let responseEvents):
                events = responseEvents
            default:
                break
            }
            
            guard events.count > 0 else {
                weakSelf.processingAccount = nil
                weakSelf.accountCompletions[accountId]?(false)
                weakSelf.accountCompletions[accountId] = nil
                weakSelf.delegates.forEach { delegate in
                    delegate?.errorRequest(accountId: accountId, response: responseData)
                }
                weakSelf.getEvents()
                return
            }
            
            let eventHandler = EventHandler(account: myAccount)
            eventHandler.handleEvents(events: events){ [weak self] result in
                weakSelf.processingAccount = nil
                guard let weakSelf = self else {
                    self?.getEvents()
                    return
                }
                
                if repeatRequest {
                    weakSelf.accountRequests.append(accountId)
                }
                weakSelf.accountCompletions[accountId]?(true)
                weakSelf.accountCompletions[accountId] = nil
                weakSelf.delegates.forEach { delegate in
                    delegate?.finishRequest(accountId: accountId, result: result)
                }
                weakSelf.getEvents()
            }
        }
        
    }
    
    func getAccountEvents(accountId: String, get: Bool = true) {
        guard !isInQueue(accountId: accountId) else {
            return
        }
        accountRequests.append(accountId)
        if get {
            getEvents()
        }
    }
    
    func getAccountsEvents() {
        let accounts = DBManager.getInactiveAccounts()
        for acc in accounts {
            getAccountEvents(accountId: acc.compoundKey, get: false)
        }
        getEvents()
    }
    
    func isInQueue(accountId: String) -> Bool {
        return processingAccount == accountId || accountRequests.contains(accountId)
    }
    
    func clearPending() {
        accountRequests.removeAll()
        accountCompletions.removeAll()
    }
}
