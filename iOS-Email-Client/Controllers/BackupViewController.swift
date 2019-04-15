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
            self.handleProgress()
            processMessage = String.localize("BACKUP_GENERATING")
            uploading = true
        }
        
        navigationItem.title = String.localize("BACKUP")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let nib = UINib(nibName: "SettingsOptionTableCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "optionCell")
        let headerNib = UINib(nibName: "BackupHeaderView", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "headerCell")
        self.fillOptions()
        
        fetchBackupData()
        toggleOptions()
        applyTheme()
    }
    
    func fetchBackupData() {
        if let cloudUrl = containerUrl?.appendingPathComponent("backup.db"),
            let attrs = try? FileManager.default.attributesOfItem(atPath: cloudUrl.path) {
            let NSlastBackupDate = attrs[.modificationDate] as? NSDate
            let NSlastBackupSize = attrs[.size] as? NSNumber
            lastBackupDate = NSlastBackupDate as Date?
            lastBackupSize = NSlastBackupSize?.intValue
        }
    }
    
    func fillOptions() {
        let enableBackup = myAccount.hasCloudBackup
        let cloud = BackupOption(label: .cloud, pick: nil, isOn: enableBackup, hasFlow: false, detail: nil, isEnabled: true)
        let now = BackupOption(label: .now, pick: nil, isOn: nil, hasFlow: false, detail: nil, isEnabled: enableBackup)
        let auto = BackupOption(label: .auto, pick: BackupFrequency.off.rawValue, isOn: nil, hasFlow: false, detail: String.localize("BACKUP_AUTO_MESSAGE"), isEnabled: enableBackup)
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
        guard !uploading else {
            return
        }
        progress = 0
        uploading = true
        processMessage = String.localize("BACKUP_GENERATING")
        tableView.reloadData()
        BackupManager.shared.backupNow(account: self.myAccount)
        handleProgress()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell") as! PrivacyUIViewCell
        let option = options[indexPath.row]
        cell.selectionStyle = UITableViewCellSelectionStyle.none
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
        return (uploading || lastBackupDate != nil) ? 180 : 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]
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
        guard !myAccount.hasCloudBackup else {
            DBManager.update(account: myAccount, hasCloudBackup: !myAccount.hasCloudBackup)
            BackupManager.shared.clearAccount(username: myAccount.username)
            self.toggleOptions()
            return
        }
        
        let setPassPopover = EmailSetPasswordViewController()
        setPassPopover.preferredContentSize = CGSize(width: Constants.popoverWidth, height: 295)
        setPassPopover.popoverPresentationController?.sourceView = self.view
        setPassPopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        setPassPopover.popoverPresentationController?.permittedArrowDirections = []
        setPassPopover.popoverPresentationController?.backgroundColor = ThemeManager.shared.theme.overallBackground
        setPassPopover.isBackup = true
        setPassPopover.onSetPassword = { [weak self] (active, password) in
            guard let weakSelf = self else {
                return
            }
            DBManager.update(account: weakSelf.myAccount, hasCloudBackup: !weakSelf.myAccount.hasCloudBackup, password: password)
            weakSelf.toggleOptions()
        }
        
        self.present(setPassPopover, animated: true)
    }
    
    func toggleOptions() {
        self.options = options.map { (option) -> BackupOption in
            var newOption = option
            let enableBackup = myAccount.hasCloudBackup
            switch(option.label) {
            case .cloud:
                newOption.isOn = enableBackup
            case .now:
                newOption.isEnabled = enableBackup
            case .auto:
                let pick = BackupFrequency.init(rawValue: myAccount.autoBackupFrequency) ?? .off
                newOption.pick = pick.rawValue
                newOption.isEnabled = enableBackup
            }
            return newOption
        }
        tableView.reloadData()
    }
}

extension BackupViewController {
    func handleProgress() {
        guard let url = containerUrl?.appendingPathComponent("backup.db") else {
            self.showAlert("Cloud Error", message: "Unable to access your Cloud Drive. Check if you have Cloud Drive enabled for Criptext.", style: .alert)
            self.uploading = false
            tableView.reloadData()
            return
        }
        query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        
        query.predicate = NSPredicate(format: "%K ==[cd] %@", NSMetadataItemPathKey, url.path)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdate), name: NSNotification.Name.NSMetadataQueryDidUpdate, object: nil)
        query.enableUpdates()
        query.start()
    }
    
    @objc func didUpdate(not: NSNotification) {
        guard let items = not.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem] else {
            return
        }
        self.query.disableUpdates()
        for mdItem in items {
            guard !((mdItem.value(forKey: NSMetadataUbiquitousItemIsUploadedKey) as? NSNumber)?.boolValue ?? false) else {
                uploading = false
                processMessage = String.localize("BACKUP_SUCCESS")
                self.progress = 1.0
                self.fetchBackupData()
                tableView.reloadData()
                query.stop()
                return
            }
            guard (mdItem.value(forKey: NSMetadataUbiquitousItemIsUploadingKey) as? NSNumber)?.boolValue ?? false,
                let progress = mdItem.value(forKey: NSMetadataUbiquitousItemPercentUploadedKey) as? NSNumber else {
                return
            }
            uploading = true
            processMessage = String.localize("BACKUP_PROGRESS", arguments: progress.intValue)
            self.progress = progress.floatValue/100
            tableView.reloadData()
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
