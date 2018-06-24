//
//  SendMailAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 6/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework
import RealmSwift

class SendMailAsyncTask {
    
    let threadId: String?
    let subject: String
    let body: String
    let guestEmails: [String: Any]
    let criptextEmails: [String: Any]
    let files: [[String: Any]]
    
    init(threadId: String?, subject: String, body: String, guestEmails: [String: Any], criptextEmails: [String: Any], files: [[String: Any]]){
        self.subject = subject
        self.body = body
        self.guestEmails = guestEmails
        self.criptextEmails = criptextEmails
        self.files = files
        self.threadId = threadId
    }
    
    func start(completion: @escaping ((Error?, Any?) -> Void)){
        DispatchQueue.global(qos: .background).async {
            self.getSessionAndEncrypt(completion: completion)
        }
    }
    
    func getSessionAndEncrypt(completion: @escaping ((Error?, Any?) -> Void)){
        let defaults = UserDefaults.standard
        let myAccount = DBManager.getAccountByUsername(defaults.string(forKey: "activeAccount")!)!
        print(myAccount)
        var recipients = [String]()
        var knownAddresses = [String: [Int32]]()
        var criptextEmailsData = [[String: Any]]()
        for (recipientId, type) in criptextEmails {
            let recipientSessions = DBManager.getSessionRecords(recipientId: recipientId)
            let deviceIds = recipientSessions.map { $0.deviceId }
            recipients.append(recipientId)
            for deviceId in deviceIds {
                let message = SignalHandler.encryptMessage(body: body, deviceId: deviceId, recipientId: recipientId, account: myAccount)
                let criptextEmail = ["recipientId": recipientId,
                                     "deviceId": deviceId,
                                     "type": type,
                                     "body": message.0,
                                     "messageType": message.1.rawValue] as [String: Any]
                criptextEmailsData.append(criptextEmail)
            }
            knownAddresses[recipientId] = deviceIds
        }
        
        let params = [
            "recipients": recipients,
            "knownAddresses": knownAddresses
            ] as [String : Any]
        
        APIManager.getKeysRequest(params, token: myAccount.jwt) { (err, response) in
            guard let keysArray = response as? [[String: Any]] else {
                completion(err, nil)
                return
            }
            let myAccount2 = DBManager.getAccountByUsername(defaults.string(forKey: "activeAccount")!)!
            for keys in keysArray {
                let recipientId = keys["recipientId"] as! String
                let deviceId = keys["deviceId"] as! Int32
                let type = self.criptextEmails[recipientId] as! String
                
                SignalHandler.buildSession(recipientId: recipientId, deviceId: deviceId, keys: keys, account: myAccount2)
                let message = SignalHandler.encryptMessage(body: self.body, deviceId: deviceId, recipientId: recipientId, account: myAccount2)
                let criptextEmail = ["recipientId": recipientId,
                                     "deviceId": deviceId,
                                     "type": type,
                                     "body": message.0,
                                     "messageType": message.1.rawValue] as [String: Any]
                criptextEmailsData.append(criptextEmail)
            }
            self.sendMail(criptextEmails: criptextEmailsData, completion: completion)
        }
    }
    
    func sendMail(criptextEmails: [Any], completion: @escaping ((Error?, Any?) -> Void)){
        let defaults = UserDefaults.standard
        let myAccount = DBManager.getAccountByUsername(defaults.string(forKey: "activeAccount")!)!
        print(myAccount)
        var requestParams = [
            "subject": subject,
            "criptextEmails": criptextEmails] as [String : Any]
        if (!files.isEmpty) {
            requestParams["files"] = files
        }
        if let thread = self.threadId {
            requestParams["threadId"] = thread
        }
        APIManager.postMailRequest(requestParams, token: myAccount.jwt) { (error, data) in
            if let error = error {
                completion(error, nil)
                return
            }
            completion(nil, data)
        }
    }
    
}
