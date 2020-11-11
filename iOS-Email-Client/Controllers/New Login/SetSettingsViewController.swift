//
//  SetSettingsViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/10/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class SetSettingsViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var continueButton: UIButton!
    
    internal struct SetSetting {
        let setting: SetSettingsTableViewCell.Setting
        var activated: Bool
    }
    var setSettings: [SetSetting] = []
    weak var myAccount: Account!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setSettings.append(SetSetting(setting: .theme, activated: false))
        setSettings.append(SetSetting(setting: .contacts, activated: false))
        setSettings.append(SetSetting(setting: .notifications, activated: false))
        setSettings.append(SetSetting(setting: .backup, activated: false))
        
        applyTheme()
        applyLocalization()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.mainText
        self.view.backgroundColor = theme.overallBackground
    }
    
    func applyLocalization() {
        titleLabel.text = String.localize("SET_TITLE")
        messageLabel.text = String.localize("SET_MESSAGE")
        continueButton.setTitle(String.localize("CONTINUE"), for: .normal)
    }
    
    @IBAction func onContinuePress() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let mailboxVC = delegate.initMailboxRootVC(nil, myAccount, showRestore: false)
        var options = UIWindow.TransitionOptions()
        options.direction = .toTop
        options.duration = 0.4
        options.style = .easeOut
        UIApplication.shared.keyWindow?.setRootViewController(mailboxVC, options: options)
    }
}

extension SetSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return setSettings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "setsettingstableviewcell", for: indexPath) as! SetSettingsTableViewCell
        let setting = setSettings[indexPath.row]
        cell.setContent(setting: setting.setting, activated: setting.activated)
        cell.onToggle = { (_, activated) in
            self.handleSettingToggle(index: indexPath.row, activated: activated)
        }
        cell.setting = setting.setting
        cell.applyTheme()
        return cell
    }
    
    func handleSettingToggle(index: Int, activated: Bool) {
        setSettings[index].activated = activated
        let setting = setSettings[index]
        switch setting.setting {
        case .theme:
            ThemeManager.shared.swapTheme(theme: activated ? Theme.dark() : Theme())
            applyTheme()
        case .contacts:
            if(setting.activated){
                let syncContactsTask = RetrieveContactsTask(accountId: myAccount.compoundKey)
                syncContactsTask.start { [weak self] (success) in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.setSettings[index].activated = success
                    weakSelf.tableView.reloadData()
                }
            }
        case .notifications:
            if(setting.activated){
                guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                delegate.registerPushNotifications()
            }
        case .backup:
            if (setting.activated) {
                let defaults = CriptextDefaults()
                guard BackupManager.shared.hasCloudAccessDir(email: self.myAccount.email) else {
                    self.showAlert(String.localize("CLOUD_ERROR"), message: String.localize("CLOUD_ERROR_MSG"), style: .alert)
                    setSettings[index].activated = false
                    return
                }
                DBManager.update(account: self.myAccount, hasCloudBackup: !self.myAccount.hasCloudBackup)
                DBManager.update(account: self.myAccount, frequency: BackupFrequency.daily.rawValue)
                BackupManager.shared.clearAccount(accountId: self.myAccount.compoundKey)
                BackupManager.shared.backupNow(account: self.myAccount)
                defaults.setShownAutobackup(email: self.myAccount.email)
            } else {
                
            }
        }
        self.tableView.reloadData()
    }
}
