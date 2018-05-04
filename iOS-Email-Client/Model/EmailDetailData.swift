//
//  EmailDetailData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class EmailDetailData{
    var emails = [Email]()
    var labels = [Label]()
    var subject = ""
    var accountEmail = ""
    var threadId : String
    init(threadId: String){
        self.threadId = threadId
    }
}
