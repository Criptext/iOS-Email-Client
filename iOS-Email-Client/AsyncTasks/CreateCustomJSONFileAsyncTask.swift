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
import FirebaseCrashlytics

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
    
    init(accountId: String, kind: Kind = .link) {
        self.accountId = accountId
        self.fileURL = kind.url
    }
    
    let fileURL: URL
    var contacts = [String: Int]()
    var emails = [Int: Int]()
    var accountId: String
    
    func start(progressHandler: @escaping ((Int) -> Void), completion: @escaping ((Error?, URL?) -> Void)){
        try? FileManager.default.removeItem(at: fileURL)
        DispatchQueue.global().async {
            self.createDBFile(progressHandler: progressHandler, completion: completion)
        }
    }
    
    private func createDBFile(progressHandler: @escaping ((Int) -> Void), completion: @escaping ((Error?, URL?) -> Void)){
        let account = DBManager.getAccountById(self.accountId)
        let results = DBManager.retrieveWholeDB(account: account!)
        var progress = handleProgress(progress: 0, total: results.total, step: results.step, progressHandler: progressHandler)
        
        let metadata = LinkFileHeaderData(recipientId: account!.username, domain: account!.domain ?? Env.plainDomain)
        metadata.fillFromAccount(account!)
        metadata.darkTheme = CriptextDefaults().themeMode == "Dark"
        metadata.language = Env.language
        
        handleRow(metadata.toDictionary())
        results.contacts.enumerated().forEach { (index, contact) in
            autoreleasepool {
                contacts[contact.email] = index + 1
                let dictionary = contact.toDictionary(id: index + 1)
                handleRow(dictionary)
                progress = handleProgress(progress: progress, total: results.total, step: results.step, progressHandler: progressHandler)
            }
        }
        results.labels.forEach { label in
            autoreleasepool {
                handleRow(label.toDictionary())
                progress = handleProgress(progress: progress, total: results.total, step: results.step, progressHandler: progressHandler)
            }
        }
        results.emails.enumerated().forEach { (index, email) in
            autoreleasepool {
                emails[email.key] = index + 1
                let dictionary = email.toDictionary(
                    id: index + 1,
                    emailBody: FileUtils.getBodyFromFile(account: account!, metadataKey: "\(email.key)"),
                    headers: FileUtils.getHeaderFromFile(account: account!, metadataKey: "\(email.key)"))
                handleRow(dictionary)
                progress = handleProgress(progress: progress, total: results.total, step: results.step, progressHandler: progressHandler)
            }
        }
        results.emails.forEach { (email) in
            autoreleasepool {
                email.toDictionaryLabels(emailsMap: emails).forEach({ (emailLabelDictionary) in
                    guard let jsonString = Utils.convertToJSONString(dictionary: emailLabelDictionary) else {
                        return
                    }
                    writeRowToFile(jsonRow: jsonString)
                    progress = handleProgress(progress: progress, total: results.total, step: results.step, progressHandler: progressHandler)
                })
            }
        }
        results.emailContacts.enumerated().forEach { (index, emailContact) in
            autoreleasepool {
                guard let emailId = emails[emailContact.email.key] else {
                    return
                }
                handleRow(emailContact.toDictionary(id: index + 1, emailId: emailId, contactId: contacts[emailContact.contact.email]!))
                progress = handleProgress(progress: progress, total: results.total, step: results.step, progressHandler: progressHandler)
            }
        }
        var fileId = 1
        results.emails.forEach { (email) in
            autoreleasepool {
                email.files.enumerated().forEach({ (index, file) in
                    guard let emailId = emails[file.emailId] else {
                        return
                    }
                    handleRow(file.toDictionary(id: fileId, emailId: emailId))
                    progress = handleProgress(progress: progress, total: results.total, step: results.step, progressHandler: progressHandler)
                    fileId += 1
                })
            }
        }
        var aliasId = 1
        results.aliases.forEach { alias in
            autoreleasepool {
                handleRow(alias.toDictionary(id: aliasId))
                progress = handleProgress(progress: progress, total: results.total, step: results.step, progressHandler: progressHandler)
                aliasId += 1
            }
        }
        var customDomainId = 1
        results.customDomains.forEach { domain in
            autoreleasepool {
                handleRow(domain.toDictionary(id: customDomainId))
                progress = handleProgress(progress: progress, total: results.total, step: results.step, progressHandler: progressHandler)
                customDomainId += 1
            }
        }
        DispatchQueue.main.async {
            completion(nil, self.fileURL)
        }
    }
    
    private func handleRow(_ row: [String: Any], appendNewLine: Bool = true){
        guard let jsonString = Utils.convertToJSONString(dictionary: row) else {
            let codeName = "LINK_FILE_ROW"
            let payload = [
                "name": "JSON ERROR",
                "reason": "INVALID JSON FORMAT",
                "row": (row["table"] as? String == "email") ? "PROTECTED_TABLE" : row,
                "codeName": codeName
                ] as [String : Any]
            Crashlytics.crashlytics().record(error: NSError.init(domain: codeName, code: -2000, userInfo: payload))
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
    
    private func handleProgress(progress: Int, total: Int, step: Int, progressHandler: @escaping ((Int) -> Void)) -> Int {
        let newProgress = progress + 1
        guard step > 0 else {
            DispatchQueue.main.async {
                progressHandler(newProgress * 100 / total)
            }
            return newProgress
        }
        guard newProgress % step == 0 else {
            return newProgress
        }
        DispatchQueue.main.async {
            progressHandler(newProgress * 100 / total)
        }
        return newProgress
    }
}
