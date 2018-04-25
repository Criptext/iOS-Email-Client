//
//  mailboxData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class MailboxData {
    var selectedLabel = SystemLabel.inbox.id
    var emailArray = [Email]()
    var filteredEmailArray = [Email]()
    var threadHash = [String:[Email]]()
    var threadToOpen:String?
    var isCustomEditing = false
    var unreadMails = 0
    var reachedEnd = false
    var loading = false
    var removeSelectedRow = false
    var fetchWorker: DispatchWorkItem?
}
