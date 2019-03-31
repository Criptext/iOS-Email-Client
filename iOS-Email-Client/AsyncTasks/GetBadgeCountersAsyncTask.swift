//
//  GetBadgeCountersAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Allisson on 2/21/19.
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
    
    let username: String
    
    init(username: String) {
        self.username = username
    }
    
    func start(completionHandler: @escaping ((Counter) -> Void)){
        let queue = DispatchQueue(label: "com.criptext.mail.badges", qos: .userInitiated, attributes: .concurrent)
        queue.async {
            guard let myAccount = DBManager.getAccountByUsername(self.username) else {
                completionHandler(Counter())
                return
            }
            var counter = Counter()
            counter.inbox = DBManager.getUnreadMailsCounter(from: SystemLabel.inbox.id, account: myAccount)
            counter.draft = DBManager.getThreads(from: SystemLabel.draft.id, since: Date(), limit: 100, account: myAccount).count
            counter.spam = DBManager.getUnreadMailsCounter(from: SystemLabel.spam.id, account: myAccount)
            
            let accounts = DBManager.getInactiveAccounts()
            accounts.forEach({ (account) in
                let counterValue = DBManager.getUnreadMailsCounter(from: SystemLabel.inbox.id, account: account)
                counter.accounts[account.username] = counterValue
            })
            
            DispatchQueue.main.async {
                completionHandler(counter)
            }
        }
    }
}
