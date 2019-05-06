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
    let queue = DispatchQueue(label: "com.criptext.account.backup", qos: .userInitiated, attributes: .concurrent)
    
    func checkAccounts() {
        let accounts = DBManager.getLoggedAccounts()
        for account in accounts {
            guard account.hasCloudBackup,
                !runningBackups.contains(account.compoundKey),
                let frequency = BackupFrequency.init(rawValue: account.autoBackupFrequency),
                frequency != .off else {
                continue
            }
            guard let worker = workers[account.compoundKey],
                worker.frequency == frequency else {
                workers[account.compoundKey]?.worker.cancel()
                workers[account.compoundKey] = nil
                let lastBackup = account.lastTimeBackup ?? Date()
                createWorker(account: account, lastBackup: lastBackup)
                continue
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
            self.runningBackups.insert(username)
            let createDBTask = CreateCustomJSONFileAsyncTask(username: username, kind: .backup)
            createDBTask.start { (_, url) in
                self.queue.async {
                    self.handleCustomFile(url: url, email: email, username: username)
                }
            }
        }
        queue.asyncAfter(deadline: .now() + executionTime.0, execute: workItem)
        workers[username] = BackupWorker(worker: workItem, frequency: executionTime.1)
    }
    
    func handleCustomFile(url: URL?, email: String, username: String) {
        guard let dbUrl = url,
            let compressedPath = try? AESCipher.compressFile(path: dbUrl.path, outputName: StaticFile.backupZip.name, compress: true),
            let container = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(email) else {
                self.workers[username] = nil
                self.runningBackups.remove(username)
                self.checkAccounts()
                return
        }
        
        self.checkAndMoveExistingBackup(username: username)
        let cloudUrl = container.appendingPathComponent("backup.db")
        try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.removeItem(at: cloudUrl)
        try? FileManager.default.copyItem(at: URL(fileURLWithPath: compressedPath), to: cloudUrl)
        DBManager.update(username: username, lastBackup: Date())
        self.workers[username] = nil
        self.runningBackups.remove(username)
        self.checkAccounts()
    }
    
    func checkAndMoveExistingBackup(username: String) {
        guard let myAccount = DBManager.getAccountByUsername(username),
            let containerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(myAccount.email) else {
            return
        }
        let myUrl = containerUrl.appendingPathComponent("backup.db")
        let oldUrl = containerUrl.appendingPathComponent("backup-old.db")
        do {
            var keys = Set<URLResourceKey>()
            keys.insert(.ubiquitousItemIsUploadedKey)
            
            let resourceValues = try myUrl.resourceValues(forKeys: keys)
            let isUploaded = (resourceValues.allValues[.ubiquitousItemIsUploadedKey] as? NSNumber)?.boolValue ?? false
            
            if isUploaded {
                try? FileManager.default.createDirectory(at: containerUrl, withIntermediateDirectories: true, attributes: nil)
                try? FileManager.default.removeItem(at: oldUrl)
                try FileManager.default.moveItem(at: myUrl, to: oldUrl)
            }
        } catch {
            
        }
    }
    
    func timeForExcecution(autoBackUp: String, lastBackup: Date, force: Bool = false) -> (Double, BackupFrequency)? {
        guard !force else {
            return (0, .off)
        }
        guard let autoFrequency = BackupFrequency.init(rawValue: autoBackUp),
            let dateForBackup = autoFrequency.timelapse(date: lastBackup) else {
                return nil
        }
        var timeForExcecution = dateForBackup.timeIntervalSince1970 - Date().timeIntervalSince1970
        timeForExcecution = timeForExcecution < 0 ? 0 : timeForExcecution
        return (timeForExcecution, autoFrequency)
    }
    
}
