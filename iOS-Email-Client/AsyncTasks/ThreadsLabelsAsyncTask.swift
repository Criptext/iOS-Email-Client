//
//  ThreadsLabelsAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Allisson on 2/21/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class ThreadsLabelsAsyncTask {
    let threadIds: [String]
    let eventThreadIds: [String]
    let added: [Int]
    let removed: [Int]
    let currentLabel: Int
    let username: String
    
    init(username: String, threadIds: [String], eventThreadIds: [String], added: [Int], removed: [Int], currentLabel: Int) {
        self.threadIds = threadIds
        self.eventThreadIds = eventThreadIds
        self.added = added
        self.removed = removed
        self.currentLabel = currentLabel
        self.username = username
    }
    
    func start(completion: @escaping (() -> Void)) {
        let queue = DispatchQueue(label: "com.criptext.mail.labels", qos: .userInitiated, attributes: .concurrent)
        queue.async {
            guard let myAccount = DBManager.getAccountByUsername(self.username) else {
                completion()
                return
            }
            for threadId in self.threadIds {
                DBManager.addRemoveLabelsForThreads(threadId, addedLabelIds: self.added, removedLabelIds: self.removed, currentLabel: self.currentLabel)
            }
            
            let changedLabels = self.getLabelNames(added: self.added, removed: self.removed)
            let eventData = EventData.Peer.ThreadLabels(threadIds: self.eventThreadIds, labelsAdded: changedLabels.0, labelsRemoved: changedLabels.1)
            DBManager.createQueueItem(params: ["params": eventData.asDictionary(), "cmd": Event.Peer.threadsLabels.rawValue], account: myAccount)
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    internal func getLabelNames(added: [Int], removed: [Int]) -> ([String], [String]){
        var addedNames = [String]()
        var removedNames = [String]()
        for id in added {
            guard let label = DBManager.getLabel(id) else {
                continue
            }
            addedNames.append(label.text)
        }
        for id in removed {
            guard let label = DBManager.getLabel(id) else {
                continue
            }
            removedNames.append(label.text)
        }
        return (addedNames, removedNames)
    }
}
