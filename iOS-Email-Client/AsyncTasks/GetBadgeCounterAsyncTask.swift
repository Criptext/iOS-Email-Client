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
    
    init(label: Int) {
        self.label = label
    }
    
    func start(completionHandler: @escaping ((Int, String) -> Void)){
        let queue = DispatchQueue(label: "com.criptext.mail.badge", qos: .background, attributes: .concurrent)
        queue.async {
            let label =  SystemLabel(rawValue: self.label) ?? .all
            let mailboxCounter = label == .draft
                ? DBManager.getThreads(from: self.label, since: Date(), limit: 100).count
                : DBManager.getUnreadMailsCounter(from: self.label)
            let counter = mailboxCounter > 0 ? "(\(mailboxCounter.description))" : ""
            DispatchQueue.main.async {
                completionHandler(self.label, counter)
            }
        }
    }
}
