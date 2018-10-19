//
//  CreateCustomJSONFileAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework
import RealmSwift

class CreateCustomJSONFileAsyncTask {
    
    let fileURL = CriptextFileManager.getURLForFile(name: "link-device-db")
    var contacts = [String: Int]()
    var emails = [Int: Int]()
    
    func start(completion: @escaping ((Error?, URL?) -> Void)){
        try? FileManager.default.removeItem(at: fileURL)
        DispatchQueue.global().async {
            self.createDBFile(completion: completion)
        }
    }
    
    private func createDBFile(completion: @escaping ((Error?, URL?) -> Void)){
        let results = DBManager.retrieveWholeDB()
        results.contacts.enumerated().forEach {
            contacts[$1.email] = $0 + 1
            let dictionary = $1.toDictionary(id: $0 + 1)
            handleRow(dictionary)
        }
        results.labels.forEach {handleRow($0.toDictionary())}
        results.emails.enumerated().forEach {
            emails[$1.key] = $0 + 1
            let dictionary = $1.toDictionary(id: $0 + 1)
            handleRow(dictionary)
        }
        results.emails.forEach { (email) in
            email.toDictionaryLabels(emailsMap: emails).forEach({ (emailLabelDictionary) in
                guard let jsonString = Utils.convertToJSONString(dictionary: emailLabelDictionary) else {
                    return
                }
                writeRowToFile(jsonRow: jsonString)
            })
        }
        results.emailContacts.enumerated().forEach {
            guard let emailId = emails[$1.email.key] else {
                return
            }
            handleRow($1.toDictionary(id: $0 + 1, emailId: emailId, contactId: contacts[$1.contact.email]!))
        }
        results.files.forEach {
            guard let emailId = emails[$0.emailId] else {
                return
            }
            handleRow($0.toDictionary(emailId: emailId))
        }
        results.fileKeys.forEach {
            guard let emailId = emails[$0.emailId] else {
                return
            }
            handleRow($0.toDictionary(emailId: emailId))
        }
        
        
        
        DispatchQueue.main.async {
            completion(nil, self.fileURL)
        }
    }
    
    private func handleRow(_ row: [String: Any], appendNewLine: Bool = true){
        guard let jsonString = Utils.convertToJSONString(dictionary: row) else {
            return
        }
        writeRowToFile(jsonRow: jsonString, appendNewLine: appendNewLine)
    }
    
    private func writeRowToFile(jsonRow: String, appendNewLine: Bool = true){
        let rowData = "\(jsonRow)\(appendNewLine ? "\n" : "")".data(using: .utf8)!
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let fileHandle = try! FileHandle(forUpdating: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(rowData)
            fileHandle.closeFile()
        } else {
            try! rowData.write(to: fileURL, options: .atomic)
        }
    }
}
