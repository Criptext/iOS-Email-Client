//
//  DeleteThreadsAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Allisson on 2/21/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class DeleteThreadsAsyncTask {
    let threadIds: [String]
    let eventThreadIds: [String]
    let currentLabel: Int
    let accountId: String
    
    init(accountId: String, threadIds: [String], eventThreadIds: [String], currentLabel: Int) {
        self.accountId = accountId
        self.threadIds = threadIds
        self.eventThreadIds = eventThreadIds
        self.currentLabel = currentLabel
    }
    
    func start(completion: @escaping (() -> Void)) {
        let queue = DispatchQueue(label: "com.criptext.mail.deletes", qos: .userInitiated, attributes: .concurrent)
        queue.async {
            guard let myAccount = DBManager.getAccountById(self.accountId) else {
                completion()
                return
            }
            for threadId in self.threadIds {
                DBManager.deleteThreads(threadId, label: self.currentLabel, account: myAccount)
            }
            let eventData = EventData.Peer.ThreadDeleted(threadIds: self.eventThreadIds)
            DBManager.createQueueItem(params: ["cmd": Event.Peer.threadsDeleted.rawValue, "params": eventData.asDictionary()], account: myAccount)
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
