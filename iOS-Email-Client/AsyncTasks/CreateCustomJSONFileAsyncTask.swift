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
    
    enum Kind {
        case link
        case backup
        case share
        
        var url: URL {
            switch(self){
            case .link:
                return StaticFile.emailDB.url
            case .backup:
                return StaticFile.backupDB.url
            case .share:
                return StaticFile.shareDB.url
            }
        }
    }
    
    init(username: String, kind: Kind = .link) {
        self.username = username
        self.fileURL = kind.url
    }
    
    let fileURL: URL
    var contacts = [String: Int]()
    var emails = [Int: Int]()
    var username: String
    
    func start(completion: @escaping ((Error?, URL?) -> Void)){
        try? FileManager.default.removeItem(at: fileURL)
        DispatchQueue.global().async {
            self.createDBFile(completion: completion)
        }
    }
    
    private func createDBFile(completion: @escaping ((Error?, URL?) -> Void)){
        let account = DBManager.getAccountByUsername(self.username)
        let results = DBManager.retrieveWholeDB(account: account!)
        results.contacts.enumerated().forEach {
            contacts[$1.email] = $0 + 1
            let dictionary = $1.toDictionary(id: $0 + 1)
            handleRow(dictionary)
        }
        results.labels.forEach {handleRow($0.toDictionary())}
        results.emails.enumerated().forEach {
            emails[$1.key] = $0 + 1
            let dictionary = $1.toDictionary(
                id: $0 + 1,
                emailBody: FileUtils.getBodyFromFile(account: account!, metadataKey: "\($1.key)"),
                headers: FileUtils.getHeaderFromFile(account: account!, metadataKey: "\($1.key)"))
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
        results.emails.forEach { (email) in
            email.files.enumerated().forEach({ (index, file) in
                guard let emailId = emails[file.emailId] else {
                    return
                }
                handleRow(file.toDictionary(id: index + 1, emailId: emailId))
            })
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
