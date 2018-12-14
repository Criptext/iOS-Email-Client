//
//  mailboxData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class MailboxData {
    var updating = false
    var selectedLabel = SystemLabel.inbox.id
    var queueItems: Results<QueueItem>?
    var queueToken: NotificationToken?
    var isDequeueing = false
    var emailArray = [Thread]()
    var filteredEmailArray = [Thread]()
    var emailReachedEnd = false
    var filteredReachedEnd = false
    var isCustomEditing = false
    var unreadMails = 0
    var feature: Feature? = nil
    var reachedEnd : Bool {
        get {
            return searchMode ? filteredReachedEnd : emailReachedEnd
        }
        set(reached) {
            if(searchMode){
                filteredReachedEnd = reached
            } else {
                emailReachedEnd = reached
            }
        }
    }
    var selectedThread: String? = nil
    var removeSelectedRow = false
    var fetchWorker: DispatchWorkItem?
    var searchMode = false
    var threads: [Thread] {
        get {
            return searchMode ? filteredEmailArray : emailArray
        }
        set(newEmails) {
            if(searchMode){
                filteredEmailArray = newEmails
            } else {
                emailArray = newEmails
            }
        }
    }
    
    func cancelFetchWorker(){
        fetchWorker?.cancel()
        fetchWorker = nil
    }
    
    struct Feature {
        var imageUrl: String
        var title: String
        var subtitle: String
    }
}
