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
        
        init(body: String, session: String){
            self.body = body
            self.session = session
        }
    }
    
    var subject: String
    var threadId: String?
    var fromAddressId: Int?
    var criptextEmails: [[String: Any]]
    var guestEmails: [String: Any]
    var files: [[String: Any]]?
    
    init(criptextEmails: [[String: Any]] = [[String: Any]](), guestEmails: [String: Any] = [String: Any]()) {
        subject = ""
        threadId = nil
        self.criptextEmails = criptextEmails
        self.guestEmails = guestEmails
        files = nil
    }
    
    func buildRequestData() -> [String: Any] {
        var requestParams = ["subject": subject] as [String : Any]
        if !criptextEmails.isEmpty {
            requestParams["criptextEmails"] = criptextEmails
        }
        if !guestEmails.isEmpty {
            requestParams["guestEmail"] = guestEmails
        }
        if let myFiles = self.files,
            !myFiles.isEmpty {
            requestParams["files"] = files
        }
        if let thread = self.threadId {
            requestParams["threadId"] = thread
        }
        if let addressId = self.fromAddressId {
            requestParams["fromAddressId"] = addressId
        }
        return requestParams
    }
}
