//
//  GetBadgeCounterAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Allisson on 2/21/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class GetBadgeCounterAsyncTask {
    
    var label: Int = 0
    var username: String = ""
    
    init(username: String, label: Int) {
        self.label = label
        self.username = username
    }
    
    func start(completionHandler: @escaping ((Int, String) -> Void)){
        let queue = DispatchQueue(label: "com.criptext.mail.badge", qos: .userInitiated, attributes: .concurrent)
        queue.async {
            guard let myAccount = DBManager.getAccountByUsername(self.username) else {
                completionHandler(self.label, "0")
                return
            }
            let label =  SystemLabel(rawValue: self.label) ?? .all
            let mailboxCounter = label == .draft
                ? DBManager.getThreads(from: self.label, since: Date(), limit: 100, account: myAccount).count
                : DBManager.getUnreadMailsCounter(from: self.label, account: myAccount)
            let counter = mailboxCounter > 0 ? "(\(mailboxCounter.description))" : ""
            DispatchQueue.main.async {
                completionHandler(self.label, counter)
            }
        }
    }
}
