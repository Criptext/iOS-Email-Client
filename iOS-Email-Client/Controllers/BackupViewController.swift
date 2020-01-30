//
//  BackupViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 4/3/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class BackupViewController: UIViewController {
    let PASSWORD_POPUP_HEIGHT = 295
    
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
    private let theme: Theme = ThemeManager.shared.theme
    private var alert: UIAlertController? = nil
    
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
        case export
        case restore
        
        var description: String {
            switch self {
            case .cloud:
                return String.localize("BACKUP_CLOUD")
            case .now:
                return String.localize("BACKUP_NOW")
            case .auto:
                return String.localize("BACKUP_AUTO")
            case .export:
                return String.localize("BACKUP_EXPORT")
            case .restore:
                return String.localize("BACKUP_RESTORE")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if BackupManager.shared.contains(accountId: myAccount.compoundKey) {
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
        let export = BackupOption(label: .export, text: nil, loading: false, pick: nil, isOn: nil, hasFlow: false, detail: String.localize("BACKUP_EXPORT_MESSAGE"), isEnabled: true)
        let restore = BackupOption(label: .restore, text: nil, loading: false, pick: nil, isOn: nil, hasFlow: false, detail: String.localize("BACKUP_RESTORE_MESSAGE"), isEnabled: true)
        options.append(cloud)
        options.append(now)
        options.append(auto)
        options.append(export)
        options.append(restore)
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        tableView.backgroundColor = .clear
        self.view.backgroundColor = theme.overallBackground
    }
    
    func startBackup(shouldUpload: Bool = true, password: String? = nil) {
        guard !uploading else {
            return
        }
        progress = 0
        uploading = true
        processMessage = String.localize("BACKUP_GENERATING")
        
        
        if !shouldUpload {
            let createDBTask = CreateCustomJSONFileAsyncTask(accountId: myAccount.compoundKey, kind: .share)
            createDBTask.start(progressHandler: { [weak self] progress in
                self?.progressUpdate(accountId: (self?.myAccount.compoundKey)!, progress: progress, isLocal: true)
            }) { (error, url) in
                guard let dbUrl = url,
                    let compressedPath = try? AESCipher.compressFile(path: dbUrl.path, outputName: StaticFile.shareZip.name, compress: true) else {
                        return
                }
                var filePath = compressedPath
                if let pass = password,
                    let encryptPath = AESCipher.streamEncrypt(path: compressedPath, outputName: StaticFile.shareRSA.name, bundle: AESCipher.KeyBundle(password: pass, salt: AESCipher.generateRandomBytes(length: 8)), ivData: AESCipher.generateRandomBytes(length: 16), operation: kCCEncrypt) {
                    filePath = encryptPath
                }
                self.uploading = false
                self.alert?.dismiss(animated: true, completion: nil)
                self.alert = nil
                let activityVC = UIActivityViewController(activityItems: [URL(fileURLWithPath: filePath)], applicationActivities: nil)
                activityVC.completionWithItemsHandler = { (activity, success, items, error) in
                    guard success else {
                        return
                    }
                    self.showSnackbarMessage(message: String.localize("BACKUP_SUCCESS"), permanent: false)
                }
                activityVC.modalPresentationStyle = .popover
                activityVC.popoverPresentationController?.sourceView = self.view
                activityVC.popoverPresentationController?.sourceRect = CGRect.zero
                self.present(activityVC, animated: true, completion: nil)
            }
        } else {
            tableView.reloadData()
            BackupManager.shared.backupNow(account: self.myAccount)
            handleProgress()
            toggleOptions()
        }
    }
    
    func encryptAndSaveFile(password: String? = nil) {
        startBackup(shouldUpload: false, password: password)
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
    
    func exportBackup(){
        let setPassPopover = EmailSetPasswordViewController()
        setPassPopover.isBackup = true
        setPassPopover.delegate = self
        setPassPopover.preferredContentSize = CGSize(width: Constants.popoverWidth, height: PASSWORD_POPUP_HEIGHT)
        setPassPopover.popoverPresentationController?.sourceView = self.view
        setPassPopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        setPassPopover.popoverPresentationController?.permittedArrowDirections = []
        setPassPopover.popoverPresentationController?.backgroundColor = ThemeManager.shared.theme.overallBackground
        self.present(setPassPopover, animated: true)
    }
    
    func restoreBackup() {
        let providerList = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        providerList.delegate = self;
        providerList.allowsMultipleSelection = false
        
        providerList.popoverPresentationController?.sourceView = self.view
        providerList.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        self.present(providerList, animated: true, completion: nil)
    }
    
    func showSnackbarMessage(message: String, permanent: Bool) {
        let fullString = NSMutableAttributedString(string: "")
        let attrs = [NSAttributedString.Key.font : Font.regular.size(15)!, NSAttributedString.Key.foregroundColor : UIColor.white]
        fullString.append(NSAttributedString(string: message, attributes: attrs))
        self.showSnackbar("", attributedText: fullString, buttons: "", permanent: permanent)
    }
    
}

extension BackupViewController: UIDocumentPickerDelegate {
    
    func documentMenu(didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        //show document picker
        documentPicker.delegate = self;
        
        documentPicker.popoverPresentationController?.sourceView = self.view
        documentPicker.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let validExtensions = Env.linkFileExtensions.allValues
        
        if(!validExtensions.contains(url.pathExtension)) {
            self.showSnackbarMessage(message: "Not a valid File", permanent: false)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let restoreVC = storyboard.instantiateViewController(withIdentifier: "restoreViewController") as! RestoreViewController
            restoreVC.myAccount = self.myAccount
            restoreVC.localUrl = url
            self.present(restoreVC, animated: true, completion: nil)
        }
    }
    
}

extension BackupViewController: EmailSetPasswordDelegate {
    func setPassword(active: Bool, password: String?) {
        self.encryptAndSaveFile(password: password)
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
        case .export:
            self.exportBackup()
        case .restore:
            self.restoreBackup()
        }
    }
    
    func toggleCloudBackup() {
        DBManager.update(account: myAccount, hasCloudBackup: !myAccount.hasCloudBackup)
        BackupManager.shared.clearAccount(accountId: myAccount.compoundKey)
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
            default:
                break
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
    func progressUpdate(accountId: String, progress: Int, isLocal: Bool = false) {
        if(isLocal){
            if(self.alert == nil){
                self.alert = UIAlertController(title: nil, message: String.localize("GENERATING_PROGRESS", arguments: progress), preferredStyle: .alert)
                self.alert?.setValue(NSAttributedString(string: String.localize("GENERATING_PROGRESS", arguments: progress), attributes: [NSAttributedString.Key.foregroundColor : theme.mainText]), forKey: "attributedMessage")
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.style = UIActivityIndicatorView.Style.gray
                loadingIndicator.color = theme.loader
                loadingIndicator.startAnimating();
                self.alert?.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = theme.background
                self.alert?.view.tintColor = theme.mainText
                self.alert?.view.addSubview(loadingIndicator)
                present(alert!, animated: true, completion: nil)
            } else {
                self.alert?.setValue(NSAttributedString(string: String.localize("GENERATING_PROGRESS", arguments: progress), attributes: [NSAttributedString.Key.foregroundColor : theme.mainText]), forKey: "attributedMessage")
            }
        } else {
            guard accountId == myAccount.compoundKey else {
                return
            }
            processMessage = String.localize("GENERATING_PROGRESS", arguments: progress)
            self.progress = Float(progress)/100
            tableView.reloadData()
        }
    }
}
