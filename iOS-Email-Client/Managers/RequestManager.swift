//
//  RequestManager.swift
//  iOS-Email-Client
//
//  Created by Allisson on 3/6/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol RequestDelegate: class {
    func finishRequest(username: String, result: EventData.Result)
    func errorRequest(username: String, response: ResponseData)
}

final class RequestManager: NSObject {
    static let shared = RequestManager()
    weak var delegate: RequestDelegate?
    private var accountRequests = [String]()
    var accountCompletions = [String: ((Bool) -> Void)]()
    private var processingAccount: String? = nil
    
    func getEvents() {
        guard processingAccount == nil,
            let username = accountRequests.first else {
                return
        }
        processingAccount = username
        accountRequests.removeFirst()
        let queue = DispatchQueue.global(qos: .default)
        queue.async {
            guard let myAccount = DBManager.getAccountByUsername(username) else {
                return
            }
            APIManager.getEvents(account: myAccount) { [weak self] (responseData) in
                guard let myAccount = DBManager.getAccountByUsername(username),
                    let weakSelf = self else {
                        self?.accountCompletions[username] = nil
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
                    weakSelf.delegate?.errorRequest(username: username, response: responseData)
                    weakSelf.accountCompletions[username]?(false)
                    weakSelf.accountCompletions[username] = nil
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
                        weakSelf.accountRequests.insert(username, at: 0)
                    } else {
                        weakSelf.accountCompletions[username]?(true)
                        weakSelf.accountCompletions[username] = nil
                        weakSelf.delegate?.finishRequest(username: username, result: result)
                    }
                    weakSelf.processingAccount = nil
                    weakSelf.getEvents()
                }
            }
        }
    }
    
    func getAccountEvents(username: String, get: Bool = true) {
        guard !isInQueue(username: username) else {
            return
        }
        accountRequests.append(username)
        if get {
            getEvents()
        }
    }
    
    func getAccountsEvents() {
        let accounts = DBManager.getInactiveAccounts()
        for acc in accounts {
            getAccountEvents(username: acc.username, get: false)
        }
        getEvents()
    }
    
    func isInQueue(username: String) -> Bool {
        return processingAccount == username || accountRequests.contains(username)
    }
    
    func clearPending() {
        accountRequests.removeAll()
    }
}
