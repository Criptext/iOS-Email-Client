//
//  RequestManager.swift
//  iOS-Email-Client
//
//  Created by Allisson on 3/6/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol RequestDelegate: class {
    func finishRequest(accountId: String, result: EventData.Result)
    func errorRequest(accountId: String, response: ResponseData)
}

final class RequestManager: NSObject {
    static let shared = RequestManager()
    weak var delegate: RequestDelegate?
    private var accountRequests = [String]()
    var accountCompletions = [String: ((Bool) -> Void)]()
    private var processingAccount: String? = nil
    
    func getEvents() {
        guard processingAccount == nil,
            let accountId = accountRequests.first,
            let myAccount = DBManager.getAccountById(accountId) else {
                return
        }
        processingAccount = accountId
        accountRequests.removeFirst()
        APIManager.getEvents(token: myAccount.jwt) { [weak self] (responseData) in
            guard let myAccount = DBManager.getAccountById(accountId),
                let weakSelf = self else {
                    self?.accountCompletions[accountId] = nil
                    self?.processingAccount = nil
                    self?.getEvents()
                    return
            }
            
            var events = [[String: Any]]()
            var repeatRequest = false
            switch(responseData) {
            case .SuccessAndRepeat(let responseEvents):
                events = responseEvents
                repeatRequest = true
            case .SuccessArray(let responseEvents):
                events = responseEvents
            default:
                break
            }
            
            guard events.count > 0 else {
                weakSelf.delegate?.errorRequest(accountId: accountId, response: responseData)
                weakSelf.accountCompletions[accountId]?(false)
                weakSelf.accountCompletions[accountId] = nil
                weakSelf.processingAccount = nil
                weakSelf.getEvents()
                return
            }
            
            let eventHandler = EventHandler(account: myAccount)
            eventHandler.handleEvents(events: events){ [weak self] result in
                guard let weakSelf = self else {
                    self?.processingAccount = nil
                    self?.getEvents()
                    return
                }
                
                if repeatRequest {
                    weakSelf.accountRequests.insert(accountId, at: 0)
                } else {
                    weakSelf.accountCompletions[accountId]?(true)
                    weakSelf.accountCompletions[accountId] = nil
                    weakSelf.delegate?.finishRequest(accountId: accountId, result: result)
                }
                weakSelf.processingAccount = nil
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
    }
}
