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
                !runningBackups.contains(account.compoundKey),
                let frequency = BackupFrequency.init(rawValue: account.autoBackupFrequency),
                frequency != .off else {
                return
            }
            guard let worker = workers[account.compoundKey],
                worker.frequency == frequency else {
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
    
    func contains(username: String) -> Bool {
        return runningBackups.contains(username)
    }
    
    func backupNow(account: Account) {
        guard !runningBackups.contains(account.compoundKey) else {
            return
        }
        workers[account.compoundKey]?.worker.cancel()
        workers[account.compoundKey] = nil
        createWorker(account: account, lastBackup: Date(), backupNow: true)
    }
    
    func createWorker(account: Account, lastBackup: Date, backupNow: Bool = false) {
        let username = account.username
        let email = account.email
        guard let executionTime = self.timeForExcecution(autoBackUp: account.autoBackupFrequency, lastBackup: lastBackup, force: backupNow) else {
            return
        }
        let workItem = DispatchWorkItem {
            print("STARTING BACKUP!!")
            self.runningBackups.insert(username)
            let createDBTask = CreateCustomJSONFileAsyncTask(username: username, kind: .backup)
            createDBTask.start { (error, url) in
                guard let dbUrl = url,
                    let compressedPath = try? AESCipher.compressFile(path: dbUrl.path, outputName: StaticFile.backupZip.name, compress: true),
                    let container = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(email) else {
                        return
                }
                let cloudUrl = container.appendingPathComponent("backup.db")
                try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true, attributes: nil)
                try? FileManager.default.removeItem(at: cloudUrl)
                try? FileManager.default.copyItem(at: URL(fileURLWithPath: compressedPath), to: cloudUrl)
                self.workers[email] = nil
                DBManager.update(username: username, lastBackup: Date())
                self.runningBackups.remove(username)
                print("FINISHING BACKUP!!")
            }
        }
        let queue = DispatchQueue(label: "com.criptext.account.backup", qos: .userInitiated, attributes: .concurrent)
        queue.asyncAfter(deadline: .now() + executionTime.0, execute: workItem)
        workers[email] = BackupWorker(worker: workItem, frequency: executionTime.1)
    }
    
    func timeForExcecution(autoBackUp: String, lastBackup: Date, force: Bool = false) -> (Double, BackupFrequency)? {
        guard !force else {
            return (0, .off)
        }
        guard let autoFrequency = BackupFrequency.init(rawValue: autoBackUp),
            let dateForBackup = autoFrequency.timelapse(date: lastBackup) else {
                return nil
        }
        var timeForExcecution = dateForBackup.timeIntervalSince1970 - lastBackup.timeIntervalSince1970
        timeForExcecution = timeForExcecution < 0 ? 0 : timeForExcecution
        return (timeForExcecution, autoFrequency)
    }
    
}
