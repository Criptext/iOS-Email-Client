//
//  SendEmailData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SendEmailData {
    struct GuestContent {
        let body: String
        let session: String
        let salt: String
        let iv: String
        
        init(body: String, session: String, salt: String, iv: String){
            self.body = body
            self.session = session
            self.salt = salt
            self.iv = iv
        }
    }
}
