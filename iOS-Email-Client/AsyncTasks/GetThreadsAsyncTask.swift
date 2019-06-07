//
//  GetThreadsAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Allisson on 5/6/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class GetThreadsAsyncTask {
    var isCancelled = false
    var date: Date
    var threads: [Thread]
    var limit: Int
    var accountId: String
    var searchText: String?
    var showAll: Bool
    var selectedLabel: Int
    
    init(accountId: String, since date: Date, threads: [Thread], limit: Int = 0, searchText: String? = nil, showAll: Bool, selectedLabel: Int) {
        self.accountId = accountId
        self.date = date
        self.threads = threads
        self.limit = limit
        self.searchText = searchText
        self.showAll = showAll
        self.selectedLabel = selectedLabel
    }
    
    func start(completionHandler: @escaping (([Thread]) -> Void)){
        let queue = DispatchQueue(label: "com.criptext.mail.threads", qos: .userInitiated, attributes: .concurrent)
        queue.async {
            guard !self.isCancelled else {
                return
            }
            var threads = [Thread]()
            autoreleasepool {
                guard let myAccount = DBManager.getAccountById(self.accountId) else {
                    completionHandler([])
                    return
                }
                let fetchedThreads = self.threads.map({$0.threadId})
                if let searchParam = self.searchText {
                    threads = DBManager.getThreads(since: self.date, searchParam: searchParam, threadIds: fetchedThreads, account: myAccount)
                } else {
                    if(self.showAll){
                        threads = DBManager.getThreads(from: self.selectedLabel, since: self.date, limit: self.limit, threadIds: fetchedThreads, account: myAccount)
                    }
                    else{
                        threads = DBManager.getUnreadThreads(from: self.selectedLabel, since: self.date, threadIds: fetchedThreads, account: myAccount)
                    }
                }
            }
            guard !self.isCancelled else {
                return
            }
            DispatchQueue.main.async {
                completionHandler(threads)
            }
        }
    }
    
    func cancel() {
        isCancelled = true
    }
}
