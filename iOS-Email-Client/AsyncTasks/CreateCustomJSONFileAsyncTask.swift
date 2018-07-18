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
    
    func start(completion: @escaping ((Error?, URL?) -> Void)){
        try? FileManager.default.removeItem(at: fileURL)
        DispatchQueue.global().async {
            self.createDBFile(completion: completion)
        }
    }
    
    private func createDBFile(completion: @escaping ((Error?, URL?) -> Void)){
        let results = DBManager.retrieveWholeDB()
        (results["contacts"] as! Results<Contact>).forEach {handleRow($0)}
        (results["labels"] as! Results<Label>).forEach {handleRow($0)}
        let emails = results["emails"] as! Results<Email>
        emails.forEach {handleRow($0)}
        emails.forEach { (email) in
            email.toDictionaryLabels().forEach({ (emailLabelDictionary) in
                guard let jsonString = Utils.convertToJSONString(dictionary: emailLabelDictionary) else {
                    return
                }
                writeRowToFile(jsonRow: jsonString)
            })
        }
        (results["emailContacts"] as! Results<EmailContact>).forEach {handleRow($0)}
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
