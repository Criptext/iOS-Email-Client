//
//  GetBadgeCounterAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 2/21/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class GetBadgeCounterAsyncTask {
    
    var label: Int = 0
    var accountId: String = ""
    
    init(accountId: String, label: Int) {
        self.label = label
        self.accountId = accountId
    }
    
    func start(completionHandler: @escaping ((Int, String) -> Void)){
        let queue = DispatchQueue(label: "com.criptext.mail.badge", qos: .userInitiated, attributes: .concurrent)
        queue.async {
            var counter = ""
            autoreleasepool {
                guard let myAccount = DBManager.getAccountById(self.accountId) else {
                    completionHandler(self.label, "0")
                    return
                }
                let label =  SystemLabel(rawValue: self.label) ?? .all
                let mailboxCounter = label == .draft
                    ? DBManager.getDraftCounter(account: myAccount)
                    : DBManager.getUnreadMailsCounter(from: self.label, account: myAccount)
                counter = mailboxCounter > 0 ? "(\(mailboxCounter.description))" : ""
            }
            DispatchQueue.main.async {
                completionHandler(self.label, counter)
            }
        }
    }
}
