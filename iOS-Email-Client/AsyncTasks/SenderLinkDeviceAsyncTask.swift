//
//  SenderLinkDeviceAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework
import RealmSwift

class SenderLinkDeviceAsyncTask {
    
    let fileURL = CriptextFileManager.getURLForFile(name: "link-device-\(Date().timeIntervalSince1970)")
    
    func start(completion: @escaping ((Error?, Any?) -> Void)){
        try? FileManager.default.removeItem(at: fileURL)
        let queue = DispatchQueue(label: "com.email.senderlink", qos: .background, attributes: .concurrent)
        queue.async {
            self.createDBFile()
        }
    }
    
    func createDBFile(){
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
                print(jsonString)
                writeRowToFile(jsonRow: jsonString)
            })
        }
        let emailContacts = results["emailContacts"] as! Results<EmailContact>
        emailContacts.forEach { (emailContact) in
            handleRow(emailContact)
        }
        let files = results["files"] as! Results<File>
        files.forEach { (file) in
            handleRow(file)
        }
    }
    
    private func handleRow(_ row: Any){
        guard let item = row as? CustomDictionary else {
            return
        }
        guard let jsonString = Utils.convertToJSONString(dictionary: item.toDictionary()) else {
            return
        }
        print(jsonString)
        writeRowToFile(jsonRow: jsonString)
    }
    
    private func writeRowToFile(jsonRow: String){
        let rowData = "\(jsonRow)\n".data(using: .utf8)!
        if FileManager.default.fileExists(atPath: fileURL.absoluteString) {
            let fileHandle = try! FileHandle(forUpdating: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(rowData)
            fileHandle.closeFile()
        } else {
            try! rowData.write(to: fileURL, options: .atomic)
        }
    }
}
