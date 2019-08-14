//
//  MarkThreadsAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 2/21/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class MarkThreadsAsyncTask {
    let threadIds: [String]
    let eventThreadIds: [String]
    let unread: Bool
    let currentLabel: Int
    let accountId: String
    
    init(accountId: String, threadIds: [String], eventThreadIds: [String], unread: Bool, currentLabel: Int) {
        self.threadIds = threadIds
        self.eventThreadIds = eventThreadIds
        self.unread = unread
        self.currentLabel = currentLabel
        self.accountId = accountId
    }
    
    func start(completion: @escaping (() -> Void)) {
        let queue = DispatchQueue(label: "com.criptext.mail.mark", qos: .userInitiated, attributes: .concurrent)
        queue.async {
            guard let myAccount = DBManager.getAccountById(self.accountId) else {
                completion()
                return
            }
            for threadId in self.threadIds {
                DBManager.updateThread(threadId: threadId, currentLabel: self.currentLabel, unread: self.unread, account: myAccount)
            }
            let params = ["cmd": Event.Peer.threadsUnread.rawValue,
                          "params": [
                            "unread": self.unread ? 1 : 0,
                            "threadIds": self.eventThreadIds
                ]
                ] as [String : Any]
            DBManager.createQueueItem(params: params, account: myAccount)
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
