//
//  RestoreUIPopover.swift
//  iOS-Email-Client
//
//  Created by Allisson on 4/9/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class RestoreUIPopover: BaseUIPopover {
    
    struct BackupData {
        var url: URL
        var size: Int
        var date: Date
    }
    
    var onRestore: (() -> Void)?
    var backupData: BackupData?
    var myAccount: Account!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    var metaQuery: NSMetadataQuery!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    var containerUrl: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(myAccount.email)
    }
    
    init(){
        super.init("RestoreUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyTheme()
        
        guard let backup = backupData else {
            titleLabel.text = "Unauthorized"
            messageLabel.text = "Enable iCloud Drive to check for backup data"
            restoreButton.setTitle(String.localize("RETRY"), for: .normal)
            return
        }
        
        self.setContent(backup: backup)
        if backup.size == 0 {
            handleMetadataQuery(url: backup.url)
        }
    }
    
    func fetchBackupData() {
        var keys = Set<URLResourceKey>()
        keys.insert(.ubiquitousItemIsUploadedKey)
        
        guard backupData == nil,
            let url = containerUrl?.appendingPathComponent("backup.db"),
            let resourceValues = try? url.resourceValues(forKeys: keys) else {
            return
        }
        
        let hasBackup = (resourceValues.allValues[.ubiquitousItemIsUploadedKey] as? Bool) ?? false
        guard hasBackup else {
            return
        }
        
        let NSlastBackupDate = resourceValues.allValues[.volumeCreationDateKey] as? NSDate
        let NSlastBackupSize = resourceValues.allValues[.fileSizeKey] as? NSNumber
        let lastBackupDate = NSlastBackupDate as Date? ?? Date()
        let lastBackupSize = NSlastBackupSize?.intValue ?? 0
        
        let backup = RestoreUIPopover.BackupData(url: url, size: lastBackupSize, date: lastBackupDate)
        self.backupData = backup
        setContent(backup: backup)
        if backup.size == 0 {
            handleMetadataQuery(url: backup.url)
        }
    }
    
    func setContent(backup: BackupData) {
        restoreButton.isEnabled = true
        
        let attrDate = NSMutableAttributedString(string: "\(String.localize("LAST_BACKUP")) \(DateUtils.conversationTime(backup.date) ?? "")", attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        let attrSize = NSAttributedString(string: "\n\(String.localize("BACKUP_SIZE")) \(File.prettyPrintSize(size: backup.size))", attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        
        attrDate.append(attrSize)
        
        messageLabel.attributedText = attrDate
        titleLabel.text = String.localize("BACKUP_FOUND")
        restoreButton.setTitle(String.localize("RESTORE_ICLOUD"), for: .normal)
    }
    
    func applyTheme() {
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.mainText
        view.backgroundColor = theme.background
        let attrSkip = NSAttributedString(string: String.localize("SKIP"), attributes: [.font: Font.regular.size(15)!, .foregroundColor: theme.criptextBlue, .underlineStyle: NSUnderlineStyle.styleSingle.rawValue, .underlineColor: theme.criptextBlue])
        skipButton.setAttributedTitle(attrSkip, for: .normal)
    }
    
    @IBAction func didPressSkip(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressRestore(_ sender: Any) {
        guard backupData != nil else {
            fetchBackupData()
            return
        }
        self.dismiss(animated: true) {
            self.onRestore?()
        }
    }
    
}

extension RestoreUIPopover {
    func handleMetadataQuery(url: URL) {
        metaQuery = NSMetadataQuery()
        metaQuery.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        metaQuery.predicate = NSPredicate(format: "%K ==[cd] %@", NSMetadataItemPathKey, url.path)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishGathering), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: nil)
        metaQuery.enableUpdates()
        metaQuery.start()
    }
    
    @objc func didFinishGathering(not: NSNotification) {
        self.metaQuery.disableUpdates()
        guard let item = metaQuery.results.first as? NSMetadataItem,
            let itemSize = item.value(forAttribute: NSMetadataItemFSSizeKey) as? NSNumber,
            let itemDate = (item.value(forAttribute: NSMetadataItemFSCreationDateKey) as? NSDate) as Date? else {
                self.metaQuery.stop()
                return
        }
        self.backupData?.size = itemSize.intValue
        self.backupData?.date = itemDate
        
        if let backup = backupData {
            setContent(backup: backup)
        }
        
        self.metaQuery.enableUpdates()
        self.metaQuery.stop()
    }
}
