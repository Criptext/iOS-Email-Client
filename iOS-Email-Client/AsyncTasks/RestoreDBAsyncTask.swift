//
//  RestoreDBAsyncTask.swift
//  iOS-Email-Client
//
//  Created by Allisson on 4/10/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class RestoreDBAsyncTask {
    let path: String
    let username: String
    let initialProgress: Int
    
    init(path: String, username: String, initialProgress: Int = 0) {
        self.path = path
        self.username = username
        self.initialProgress = initialProgress
    }
    
    func start(progressHandler: @escaping ((Int) -> Void), completion: @escaping (() -> Void)) {
        let queue = DispatchQueue(label: "com.email.loaddb", qos: .background, attributes: .concurrent)
        queue.async {
            let streamReader = StreamReader(url: URL(fileURLWithPath: self.path), delimeter: "\n", encoding: .utf8, chunkSize: 1024)
            var dbRows = [[String: Any]]()
            var progress = self.initialProgress
            var maps = DBManager.LinkDBMaps.init(emails: [Int: Int](), contacts: [Int: String]())
            while let line = streamReader?.nextLine() {
                guard let row = Utils.convertToDictionary(text: line) else {
                    continue
                }
                dbRows.append(row)
                if dbRows.count >= 30 {
                    DBManager.insertBatchRows(rows: dbRows, maps: &maps, username: self.username)
                    dbRows.removeAll()
                    if progress < 99 {
                        progress += 1
                    }
                    DispatchQueue.main.async {
                        progressHandler(progress)
                    }
                }
            }
            DBManager.insertBatchRows(rows: dbRows, maps: &maps, username: self.username)
            CriptextFileManager.deleteFile(path: self.path)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
