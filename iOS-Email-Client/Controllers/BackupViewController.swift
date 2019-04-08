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
        case share
        
        var description: String {
            switch self {
            case .cloud:
                return "Cloud Backup"
            case .now:
                return "Back Up Now"
            case .auto:
                return "Auto Backup"
            case .share:
                return "Create Backup File"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BackupManager.shared.clearAccount(username: myAccount.username)
        if BackupManager.shared.contains(username: myAccount.username) {
            processMessage = "Generating Backup File..."
            uploading = true
        }
        
        navigationItem.title = String.localize("BACKUP")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        self.handleProgress()
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
        let auto = BackupOption(label: .auto, pick: BackupFrequency.off.rawValue, isOn: nil, hasFlow: false, detail: "Note: Auto Backup works only with cloud backup. To avoid using your celular data, make sure you are connected to Wi-Fi or have iCloud drive disabled for celular data in Configuration > Celular Data > iCloud Drive", isEnabled: enableBackup)
        let share = BackupOption(label: .share, pick: nil, isOn: nil, hasFlow: false, detail: "Create a file generates an archive to be stored in your local device", isEnabled: enableBackup)
        options.append(cloud)
        options.append(now)
        options.append(auto)
        options.append(share)
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        tableView.backgroundColor = .clear
        self.view.backgroundColor = theme.overallBackground
    }
    
    func startBackup(upload: Bool = true) {
        guard !uploading else {
            return
        }
        progress = 0
        uploading = true
        processMessage = "Generating Backup File..."
        tableView.reloadData()
        if !upload {
            let createDBTask = CreateCustomJSONFileAsyncTask(username: myAccount.username, kind: .share)
            createDBTask.start { (error, url) in
                guard let dbUrl = url,
                    let compressedPath = try? AESCipher.compressFile(path: dbUrl.path, outputName: StaticFile.shareZip.name, compress: true) else {
                        return
                }
                self.processMessage = "Mailbox Backed Successfully!"
                self.uploading = false
                self.tableView.reloadData()
                let activityVC = UIActivityViewController(activityItems: [URL(fileURLWithPath: compressedPath)], applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }
        } else {
            BackupManager.shared.backupNow(account: self.myAccount)
            handleProgress()
        }
    }
    
    func openPicker(){
        let pickerPopover = OptionsPickerUIPopover()
        pickerPopover.options = [
            BackupFrequency.minute.rawValue,
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
        cell.emailLabel.text = myAccount.email
        cell.backupLabel.text = "Backup Size: \(lastBackupSize == nil ? "0MB" : File.prettyPrintSize(size: lastBackupSize!))"
        cell.progressLabel.text = processMessage
        cell.progressView.setProgress(progress, animated: true)
        
        if let myDate = lastBackupDate {
            cell.lastBackupLabel.text = DateUtils.date(toCompleteString: myDate).replacingOccurrences(of: "at", with: String.localize("AT"))
        }
        
        cell.detailContainerView.isHidden = !(uploading || lastBackupDate != nil)
        if uploading {
            cell.cancelButton.isHidden = false
            cell.progressView.isHidden = false
            cell.progressLabel.isHidden = false
            cell.lastBackupLabel.isHidden = true
        } else if lastBackupDate != nil {
            cell.cancelButton.isHidden = true
            cell.progressView.isHidden = true
            cell.progressLabel.isHidden = true
            cell.lastBackupLabel.isHidden = false
        } else {
            cell.cancelButton.isHidden = true
            cell.progressView.isHidden = true
            cell.progressLabel.isHidden = true
            cell.lastBackupLabel.isHidden = true
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (uploading || lastBackupDate != nil) ? 200 : 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]
        switch(option.label) {
        case .cloud:
            DBManager.update(account: myAccount, hasCloudBackup: !myAccount.hasCloudBackup)
            self.toggleOptions()
        case .now:
            self.startBackup()
        case .auto:
            self.openPicker()
        case .share:
            startBackup(upload: false)
        }
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
            case .share:
                newOption.isEnabled = enableBackup
            }
            return newOption
        }
        tableView.reloadData()
    }
}

extension BackupViewController {
    func handleProgress() {
        query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        query.predicate = NSPredicate(format: "%K ==[cd] %@", NSMetadataItemPathKey, containerUrl!.appendingPathComponent("backup.db").path)
        
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
                processMessage = "Mailbox Backed Successfully!"
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
            processMessage = "Uploading Backup... \(progress.intValue)%"
            self.progress = progress.floatValue/100
            tableView.reloadData()
        }
        self.query.enableUpdates()
    }
}

extension BackupViewController: UIGestureRecognizerDelegate {
    @objc func goBack(){
        BackupManager.shared.checkAccounts()
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
