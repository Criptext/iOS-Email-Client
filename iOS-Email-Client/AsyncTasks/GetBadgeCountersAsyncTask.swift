//
//  GetBadgeCountersAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 2/21/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class GetBadgeCountersAsyncTask {
    
    struct Counter {
        var inbox = 0
        var draft = 0
        var spam = 0
        var accounts = [String: Int]()
    }
    
    let accountId: String
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    func start(completionHandler: @escaping ((Counter) -> Void)){
        let queue = DispatchQueue(label: "com.criptext.mail.badges", qos: .userInitiated, attributes: .concurrent)
        queue.async {
            guard let myAccount = DBManager.getAccountById(self.accountId) else {
                completionHandler(Counter())
                return
            }
            var counter = Counter()
            counter.inbox = DBManager.getUnreadMailsCounter(from: SystemLabel.inbox.id, account: myAccount)
            counter.draft = DBManager.getDraftCounter(account: myAccount)
            counter.spam = DBManager.getUnreadMailsCounter(from: SystemLabel.spam.id, account: myAccount)
            
            let accounts = DBManager.getInactiveAccounts()
            accounts.forEach({ (account) in
                let counterValue = DBManager.getUnreadMailsCounter(from: SystemLabel.inbox.id, account: account)
                counter.accounts[account.compoundKey] = counterValue
            })
            
            DispatchQueue.main.async {
                completionHandler(counter)
            }
        }
    }
}
