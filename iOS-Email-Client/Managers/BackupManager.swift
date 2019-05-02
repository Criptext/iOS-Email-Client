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
    
    func clearAccount(accountId: String) {
        workers[accountId]?.worker.cancel()
        workers[accountId] = nil
    }
    
    func contains(accountId: String) -> Bool {
        return runningBackups.contains(accountId)
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
        let accountId = account.compoundKey
        let email = account.email
        guard let executionTime = self.timeForExcecution(autoBackUp: account.autoBackupFrequency, lastBackup: lastBackup, force: backupNow) else {
            return
        }
        
        let workItem = DispatchWorkItem {
            self.runningBackups.insert(accountId)
            let createDBTask = CreateCustomJSONFileAsyncTask(accountId: accountId, kind: .backup)
            createDBTask.start { (_, url) in
                self.queue.async {
                    self.handleCustomFile(url: url, email: email, accountId: accountId)
                }
            }
        }
        queue.asyncAfter(deadline: .now() + executionTime.0, execute: workItem)
        workers[accountId] = BackupWorker(worker: workItem, frequency: executionTime.1)
    }
    
    func handleCustomFile(url: URL?, email: String, accountId: String) {
        guard let dbUrl = url,
            let compressedPath = try? AESCipher.compressFile(path: dbUrl.path, outputName: StaticFile.backupZip.name, compress: true),
            let container = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(email) else {
                self.workers[accountId] = nil
                self.runningBackups.remove(accountId)
                self.checkAccounts()
                return
        }
        
        self.checkAndMoveExistingBackup(accountId: accountId)
        let cloudUrl = container.appendingPathComponent("backup.db")
        try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.removeItem(at: cloudUrl)
        try? FileManager.default.copyItem(at: URL(fileURLWithPath: compressedPath), to: cloudUrl)
        DBManager.update(accountId: accountId, lastBackup: Date())
        self.workers[accountId] = nil
        self.runningBackups.remove(accountId)
        self.checkAccounts()
    }
    
    func checkAndMoveExistingBackup(accountId: String) {
        guard let myAccount = DBManager.getAccountById(accountId),
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
        var timeForExcecution = dateForBackup.timeIntervalSince1970 - lastBackup.timeIntervalSince1970
        timeForExcecution = timeForExcecution < 0 ? 0 : timeForExcecution
        return (timeForExcecution, autoFrequency)
    }
    
}
