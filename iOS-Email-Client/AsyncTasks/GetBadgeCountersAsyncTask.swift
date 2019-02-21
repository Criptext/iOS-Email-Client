//
//  GetBadgeCountersAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Allisson on 2/21/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class GetBadgeCountersAsyncTask {
    
    struct Counter {
        var inbox = 0
        var draft = 0
        var spam = 0
    }
    
    func start(completionHandler: @escaping ((Counter) -> Void)){
        let queue = DispatchQueue(label: "com.criptext.mail.badges", qos: .background, attributes: .concurrent)
        queue.async {
            var counter = Counter()
            counter.inbox = DBManager.getUnreadMailsCounter(from: SystemLabel.inbox.id)
            counter.draft = DBManager.getThreads(from: SystemLabel.draft.id, since: Date(), limit: 100).count
            counter.spam = DBManager.getUnreadMailsCounter(from: SystemLabel.spam.id)
            DispatchQueue.main.async {
                completionHandler(counter)
            }
        }
    }
}
