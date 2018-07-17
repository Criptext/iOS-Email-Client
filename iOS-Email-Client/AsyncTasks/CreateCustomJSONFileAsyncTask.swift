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
    
    let fileURL = CriptextFileManager.getURLForFile(name: "link-device-\(Date().timeIntervalSince1970)")
    
    func start(completion: @escaping ((Error?, URL?) -> Void)){
        try? FileManager.default.removeItem(at: fileURL)
        let queue = DispatchQueue(label: "com.email.senderlink", qos: .background, attributes: .concurrent)
        queue.async {
            self.createDBFile(completion: completion)
        }
    }
    
    private func createDBFile(completion: @escaping ((Error?, URL?) -> Void)){
        let results = DBManager.retrieveWholeDB()
        let contacts = results["contacts"] as! Results<Contact>
        contacts.forEach { (contact) in
            handleRow(contact)
        }
        let labels = results["labels"] as! Results<Label>
        labels.forEach { (label) in
            handleRow(label)
        }
        let emails = results["emails"] as! Results<Email>
        emails.forEach { (email) in
            handleRow(email)
        }
        emails.forEach { (email) in
            email.toDictionaryLabels().forEach({ (emailLabelDictionary) in
                guard let jsonString = Utils.convertToJSONString(dictionary: emailLabelDictionary) else {
                    return
                }
                writeRowToFile(jsonRow: jsonString)
            })
        }
        let emailContacts = results["emailContacts"] as! Results<EmailContact>
        emailContacts.forEach { (emailContact) in
            handleRow(emailContact)
        }
        let files = results["files"] as! Results<File>
        files.forEach { (file) in
            guard file != files.last else {
                handleRow(file, appendNewLine: false)
                return
            }
            handleRow(file)
        }
        
        DispatchQueue.main.async {
            completion(nil, self.fileURL)
        }
    }
    
    private func handleRow(_ row: Any, appendNewLine: Bool = true){
        guard let item = row as? CustomDictionary else {
            return
        }
        guard let jsonString = Utils.convertToJSONString(dictionary: item.toDictionary()) else {
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
