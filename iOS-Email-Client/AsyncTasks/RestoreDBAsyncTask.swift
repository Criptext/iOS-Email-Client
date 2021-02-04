//
//  RestoreDBAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 4/10/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class RestoreDBAsyncTask {
    let path: String
    let accountId: String
    let initialProgress: Int
    
    init(path: String, accountId: String, initialProgress: Int = 0) {
        self.path = path
        self.accountId = accountId
        self.initialProgress = initialProgress
    }
    
    func start(progressHandler: @escaping ((Int) -> Void), completion: @escaping ((CriptextError?) -> Void)) {
        let queue = DispatchQueue(label: "com.email.loaddb", qos: .userInteractive, attributes: .concurrent)
        queue.async {
            guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: self.path),
                let streamReader = StreamReader(url: URL(fileURLWithPath: self.path), delimeter: "\n", encoding: .utf8, chunkSize: 2048) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            let fileSize = UInt64(truncating: fileAttributes[.size] as! NSNumber)
            var dbRows = [[String: Any]]()
            var maps = LinkDBMaps.init(emails: [Int: Int](), contacts: [Int: String]())
            let account = DBManager.getAccountById(self.accountId)!
            var line = streamReader.nextLine()
            
            guard let metadata = LinkFileHeaderData.fromDictionary(dictionary: Utils.convertToDictionary(text: line!)),
                account.email == "\(metadata.recipientId)@\(metadata.domain)",
                let fileHandler = try? LinkFileMiddleware(version: metadata.fileVersion) else {
                DispatchQueue.main.async {
                    completion(CriptextError(message: String.localize("LINK_FILE_METADATA_ERROR")))
                }
                return
            }
            
            DBManager.update(account: account, defaultAddressId: metadata.defaultAddressId ?? 0)
            
            line = streamReader.nextLine()
            while line != nil {
                autoreleasepool {
                    if let row = Utils.convertToDictionary(text: line!) {
                        var progress = Int((100 - UInt64(self.initialProgress)) * streamReader.currentPosition/fileSize) + self.initialProgress
                        dbRows.append(row)
                        if dbRows.count >= 30 {
                            fileHandler.insertBatchRows(rows: dbRows, maps: &maps, accountId: self.accountId)
                            dbRows.removeAll()
                            if progress > 99 {
                                progress = 99
                            }
                            DispatchQueue.main.async {
                                progressHandler(progress)
                            }
                        }
                    }
                    line = streamReader.nextLine()
                }
            }
            fileHandler.insertBatchRows(rows: dbRows, maps: &maps, accountId: self.accountId)
            CriptextFileManager.deleteFile(path: self.path)
            
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}
