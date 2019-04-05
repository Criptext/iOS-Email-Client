//
//  BackupManager.swift
//  iOS-Email-Client
//
//  Created by Allisson on 4/5/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

final class BackupManager {
    
    internal struct BackupWorker {
        let worker: DispatchWorkItem
        let frequency: BackupFrequency
    }
    
    static let shared = BackupManager()
    var workers = [String: BackupWorker]()
    var runningBackups = Set<String>()
    
    func checkAccounts() {
        let accounts = DBManager.getLoggedAccounts()
        for account in accounts {
            guard account.hasCloudBackup,
                let frequency = BackupFrequency.init(rawValue: account.autoBackupFrequency),
                frequency != .off else {
                return
            }
            guard let worker = workers[account.compoundKey],
                worker.frequency == frequency,
                !runningBackups.contains(account.username) else {
                workers[account.compoundKey]?.worker.cancel()
                workers[account.compoundKey] = nil
                let lastBackup = account.lastTimeBackup ?? Date()
                createWorker(account: account, lastBackup: lastBackup)
                return
            }
        }
    }
    
    func clearAccount(username: String) {
        workers[username]?.worker.cancel()
        workers[username] = nil
    }
    
    func createWorker(account: Account, lastBackup: Date) {
        let username = account.username
        let email = account.email
        guard let autoFrequency = BackupFrequency.init(rawValue: account.autoBackupFrequency),
            let dateForBackup = autoFrequency.timelapse(date: lastBackup) else {
            return
        }
        let timeForExcecution = dateForBackup.timeIntervalSince1970 - lastBackup.timeIntervalSince1970
        let workItem = DispatchWorkItem {
            self.runningBackups.insert(account.username)
            let createDBTask = CreateCustomJSONFileAsyncTask(username: username)
            createDBTask.start { (error, url) in
                guard let dbUrl = url,
                    let compressedPath = try? AESCipher.compressFile(path: dbUrl.path, outputName: StaticFile.gzippedDB.name, compress: true),
                    let container = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(email) else {
                        return
                }
                let cloudUrl = container.appendingPathComponent("backup.db")
                try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true, attributes: nil)
                try? FileManager.default.removeItem(at: cloudUrl)
                try? FileManager.default.copyItem(at: URL(fileURLWithPath: compressedPath), to: cloudUrl)
                self.workers[email] = nil
                DBManager.update(username: username, lastBackup: Date())
                self.runningBackups.remove(account.username)
            }
        }
        let queue = DispatchQueue(label: "com.criptext.account.backup", qos: .userInitiated, attributes: .concurrent)
        queue.asyncAfter(deadline: .now() + timeForExcecution, execute: workItem)
        workers[email] = BackupWorker(worker: workItem, frequency: autoFrequency)
    }
    
}
