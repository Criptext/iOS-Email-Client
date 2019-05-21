//
//  BackupViewController.swift
//  iOS-Email-Client
//
//  Created by Allisson on 4/3/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class BackupViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    weak var myAccount: Account!
    var options = [BackupOption]()
    var query: NSMetadataQuery!
    var metaQuery: NSMetadataQuery!
    var uploading = false
    var lastBackupDate: Date? = nil
    var lastBackupSize: Int? = nil
    var processMessage = ""
    var progress: Float = 0
    
    var containerUrl: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(myAccount.email)
    }
    
    struct BackupOption {
        var label: Backup
        var text: String?
        var loading: Bool
        var pick: String?
        var isOn: Bool?
        var hasFlow: Bool
        var detail: String?
        var isEnabled = true
    }
    
    enum Backup {
        case cloud
        case now
        case auto
        
        var description: String {
            switch self {
            case .cloud:
                return String.localize("BACKUP_CLOUD")
            case .now:
                return String.localize("BACKUP_NOW")
            case .auto:
                return String.localize("BACKUP_AUTO")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if BackupManager.shared.contains(username: myAccount.username) {
            processMessage = String.localize("BACKUP_GENERATING")
            uploading = true
        }
        BackupManager.shared.delegate = self
        
        navigationItem.title = String.localize("BACKUP")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let nib = UINib(nibName: "SettingsOptionTableCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "optionCell")
        let headerNib = UINib(nibName: "BackupHeaderView", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "headerCell")
        self.fillOptions()
        
        handleMetadataQuery()
        toggleOptions()
        applyTheme()
    }
    
    func fillOptions() {
        let enableBackup = myAccount.hasCloudBackup
        let cloud = BackupOption(label: .cloud, text: nil, loading: false, pick: nil, isOn: enableBackup, hasFlow: false, detail: nil, isEnabled: true)
        let now = BackupOption(label: .now, text: nil, loading: false, pick: nil, isOn: nil, hasFlow: false, detail: nil, isEnabled: enableBackup)
        let auto = BackupOption(label: .auto, text: nil, loading: false, pick: BackupFrequency.off.rawValue, isOn: nil, hasFlow: false, detail: String.localize("BACKUP_AUTO_MESSAGE"), isEnabled: enableBackup)
        options.append(cloud)
        options.append(now)
        options.append(auto)
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        tableView.backgroundColor = .clear
        self.view.backgroundColor = theme.overallBackground
    }
    
    func startBackup() {
        progress = 0
        uploading = true
        processMessage = String.localize("BACKUP_GENERATING")
        BackupManager.shared.backupNow(account: self.myAccount)
        handleProgress()
        toggleOptions()
    }
    
    func openPicker(){
        let pickerPopover = OptionsPickerUIPopover()
        pickerPopover.options = [
            BackupFrequency.daily.rawValue,
            BackupFrequency.weekly.rawValue,
            BackupFrequency.monthly.rawValue,
            BackupFrequency.off.rawValue
        ]
        pickerPopover.onComplete = { option in
            guard let selected = option else {
                return
            }
            DBManager.update(account: self.myAccount, frequency: selected)
            self.toggleOptions()
            BackupManager.shared.checkAccounts()
        }
        self.presentPopover(popover: pickerPopover, height: 295)
    }
}

enum BackupFrequency: String {
    case minute = "Minute"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case off = "Off"
    
    func timelapse(date: Date) -> Date? {
        switch self {
        case .minute:
            return Calendar.current.date(byAdding: .minute, value: 2, to: date)
        case .daily:
            return Calendar.current.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return Calendar.current.date(byAdding: .day, value: 7, to: date)
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: 1, to: date)
        case .off:
            return nil
        }
    }
}

extension BackupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell") as! SettingsOptionCell
        let option = options[indexPath.row]
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.fillFields(option: option)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "headerCell") as! BackupHeaderView
        cell.setContent(email: myAccount.email, isUploading: uploading, lastBackupDate: lastBackupDate, lastBackupSize: lastBackupSize)
        cell.progressLabel.text = processMessage
        cell.progressView.setProgress(progress, animated: true)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let HEADER_HEIGHT_WITH_BACKUP: CGFloat = 210
        let HEADER_HEIGHT_WITHOUT_BACKUP: CGFloat = 170
        return uploading ? HEADER_HEIGHT_WITH_BACKUP : HEADER_HEIGHT_WITHOUT_BACKUP
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]
        guard option.isEnabled else {
            return
        }
        switch(option.label) {
        case .cloud:
            self.toggleCloudBackup()
        case .now:
            self.startBackup()
        case .auto:
            self.openPicker()
        }
    }
    
    func toggleCloudBackup() {
        DBManager.update(account: myAccount, hasCloudBackup: !myAccount.hasCloudBackup)
        BackupManager.shared.clearAccount(username: myAccount.username)
        if myAccount.hasCloudBackup {
            startBackup()
        } else {
            toggleOptions()
        }
    }
    
    func toggleOptions() {
        self.options = options.map { (option) -> BackupOption in
            var newOption = option
            let enableBackup = myAccount.hasCloudBackup
            switch(option.label) {
            case .cloud:
                newOption.isOn = enableBackup
                newOption.isEnabled = !uploading
            case .now:
                newOption.isEnabled = (enableBackup && !uploading)
                newOption.text = uploading ? String.localize("BACKING_UP") : nil
                newOption.loading = uploading
            case .auto:
                let pick = BackupFrequency.init(rawValue: myAccount.autoBackupFrequency) ?? .off
                newOption.pick = pick.rawValue
                newOption.isEnabled = enableBackup
            }
            return newOption
        }
        tableView.reloadData()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        NotificationCenter.default.removeObserver(self)
        if let myQuery = query {
            myQuery.stop()
        }
        if let myMetaQuery = metaQuery {
            myMetaQuery.stop()
        }
    }
}

extension BackupViewController {
    func handleMetadataQuery() {
        guard let url = containerUrl?.appendingPathComponent("backup.db") else {
            return
        }
        metaQuery = NSMetadataQuery()
        metaQuery.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        metaQuery.predicate = NSPredicate(format: "%K ==[cd] %@", NSMetadataItemPathKey, url.path)
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishGathering), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: nil)
        metaQuery.start()
    }
    
    @objc func didFinishGathering(not: NSNotification) {
        self.metaQuery.disableUpdates()
        guard let item = metaQuery.results.first as? NSMetadataItem else {
            return
        }
        guard let itemSize = item.value(forAttribute: NSMetadataItemFSSizeKey) as? NSNumber,
            let itemDate = (item.value(forAttribute: NSMetadataItemFSCreationDateKey) as? NSDate) as Date? else {
                self.metaQuery.enableUpdates()
                self.metaQuery.stop()
                if (item.value(forKey: NSMetadataUbiquitousItemIsUploadingKey) as? NSNumber)?.boolValue ?? false {
                    handleProgress()
                }
                return
        }
        self.metaQuery.enableUpdates()
        self.metaQuery.stop()
        lastBackupSize = itemSize.intValue
        lastBackupDate = itemDate
        tableView.reloadData()
    }
    
    func handleProgress() {
        guard let url = containerUrl?.appendingPathComponent("backup.db") else {
            self.showAlert(String.localize("CLOUD_ERROR"), message: String.localize("CLOUD_ERROR_MSG"), style: .alert)
            self.uploading = false
            toggleOptions()
            return
        }
        query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        
        query.predicate = NSPredicate(format: "%K ==[cd] %@", NSMetadataItemPathKey, url.path)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdate), name: NSNotification.Name.NSMetadataQueryDidUpdate, object: nil)
        query.start()
    }
    
    @objc func didUpdate(not: NSNotification) {
        self.query.disableUpdates()
        guard let items = not.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem] else {
            return
        }
        for mdItem in items {
            guard !((mdItem.value(forKey: NSMetadataUbiquitousItemIsUploadedKey) as? NSNumber)?.boolValue ?? false) else {
                uploading = false
                processMessage = String.localize("BACKUP_SUCCESS")
                self.progress = 1.0
                toggleOptions()
                query.stop()
                self.handleMetadataQuery()
                return
            }
            guard (mdItem.value(forKey: NSMetadataUbiquitousItemIsUploadingKey) as? NSNumber)?.boolValue ?? false,
                let progress = mdItem.value(forKey: NSMetadataUbiquitousItemPercentUploadedKey) as? NSNumber else {
                return
            }
            processMessage = String.localize("BACKUP_PROGRESS", arguments: progress.intValue)
            self.progress = progress.floatValue/100
            if !uploading {
                uploading = true
                toggleOptions()
            } else {
                tableView.reloadData()
            }
        }
        self.query.enableUpdates()
    }
}

extension BackupViewController: UIGestureRecognizerDelegate {
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension BackupViewController: BackupDelegate {
    func progressUpdate(username: String, progress: Int) {
        guard username == myAccount.username else {
            return
        }
        processMessage = String.localize("GENERATING_PROGRESS", arguments: progress)
        self.progress = Float(progress)/100
        tableView.reloadData()
    }
}
