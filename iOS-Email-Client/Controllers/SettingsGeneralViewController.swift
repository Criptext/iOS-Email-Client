//
//  SettingsGeneralViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material
import SafariServices
import PasscodeLock

class SettingsGeneralViewController: UIViewController{
    
    internal enum Section {
        case account
        case general
        case about
        case version
        
        var name: String {
            switch(self){
            case .account:
                return String.localize("ACCOUNT")
            case .general:
                return String.localize("GENERAL")
            case .about:
                return String.localize("ABOUT")
            case .version:
                return String.localize("VERSION")
            }
        }
        
        enum SubSection {
            case account
            case privacy
            case devices
            case labels
            case manualSync
            
            case night
            case syncContact
            case preview
            case pin
            
            case faq
            case policies
            case terms
            case openSource
            
            case version
            
            var name: String {
                switch(self){
                case .syncContact:
                    return String.localize("SYNC_PHONEBOOK")
                case .privacy:
                    return String.localize("PRIVACY")
                case .terms:
                    return String.localize("TERMS")
                case .openSource:
                    return String.localize("OPEN_LIBS")
                case .version:
                    return String.localize("VERSION")
                case .night:
                    return String.localize("NIGHT_MODE")
                case .manualSync:
                    return String.localize("MANUAL_SYNC")
                case .account:
                    return String.localize("ACCOUNT_OPTION")
                case .devices:
                    return String.localize("DEVICES_OPTION")
                case .labels:
                    return String.localize("LABELS_OPTION")
                case .preview:
                    return String.localize("SHOW_PREVIEW")
                case .pin:
                    return String.localize("PIN_LOCK")
                case .faq:
                    return String.localize("FAQ")
                case .policies:
                    return String.localize("POLICY")
                }
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    let STATUS_NOT_CONFIRMED = 0
    let SECTION_VERSION = 3
    let ROW_HEIGHT: CGFloat = 40.0
    let sections = [.account, .general, .about, .version] as [Section]
    let menus = [
        .account: [.account, .privacy, .devices, .labels, .manualSync],
        .general: [.night, .syncContact, .preview, .pin],
        .about: [.faq, .policies, .terms, .openSource],
        .version : [.version]] as [Section: [Section.SubSection]
    ]
    var generalData = GeneralSettingsData()
    var devicesData = DeviceSettingsData()
    var myAccount : Account!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        ThemeManager.shared.addListener(id: "settings", delegate: self)
        self.devicesData.devices.append(Device.createActiveDevice(deviceId: myAccount.deviceId))
        self.navigationItem.title = String.localize("SETTINGS")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-rounded").tint(with: .white), style: .plain, target: self, action: #selector(dismissViewController))
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.insetsContentViewsToSafeArea = true
        
        self.applyTheme()
        self.loadData()
    }
    
    func loadData(){
        let myDevice = Device.createActiveDevice(deviceId: myAccount.deviceId)
        APIManager.getSettings(account: myAccount) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout(account: self.myAccount)
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case let .SuccessDictionary(settings) = responseData,
                let devices = settings["devices"] as? [[String: Any]],
                let general = settings["general"] as? [String: Any] else {
                    return
            }
            let myDevices = devices.map({Device.fromDictionary(data: $0)}).filter({$0.id != myDevice.id}).sorted(by: {$0.safeDate > $1.safeDate})
            self.devicesData.devices.append(contentsOf: myDevices)
            let email = general["recoveryEmail"] as! String
            let status = general["recoveryEmailConfirmed"] as! Int
            let isTwoFactor = general["twoFactorAuth"] as! Int
            let hasEmailReceipts = general["trackEmailRead"] as! Int
            let replyTo = general["replyTo"] as? String ?? ""
            self.generalData.replyTo = replyTo
            self.generalData.recoveryEmail = email
            self.generalData.recoveryEmailStatus = email.isEmpty ? .none : status == self.STATUS_NOT_CONFIRMED ? .pending : .verified
            self.generalData.isTwoFactor = isTwoFactor == 1 ? true : false
            self.generalData.hasEmailReceipts = hasEmailReceipts == 1 ? true : false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @objc func dismissViewController(){
        self.dismiss(animated: true, completion: nil)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        ThemeManager.shared.removeListener(id: "settings")
    }
    
    func applyTheme(){
        let attributedTitle = NSAttributedString(string: String.localize("GENERAL"), attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        let attributed2Title = NSAttributedString(string: String.localize("GENERAL"), attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        tableView.backgroundColor = theme.overallBackground
        self.view.backgroundColor = theme.overallBackground
        tableView.separatorColor = theme.separator
    }
    
    func renderAccountCells(subsection: Section.SubSection) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
        cell.optionLabel.textColor = theme.mainText
        cell.optionLabel.text = subsection.name
        cell.goImageView.isHidden = true
        cell.messageLabel.text = ""
        cell.loader.stopAnimating()
        cell.loader.isHidden = true
        switch(subsection){
        case .manualSync:
            cell.goImageView.isHidden = true
        default:
            cell.goImageView.isHidden = false
        }
        return cell
    }
    
    func renderGeneralCells(subsection: Section.SubSection) -> UITableViewCell {
        switch(subsection){
        case .syncContact:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
            cell.optionLabel.textColor = theme.mainText
            cell.optionLabel.text = subsection.name
            cell.messageLabel.text = ""
            switch(generalData.syncStatus){
            case .fail, .success:
                cell.loader.isHidden = true
                cell.loader.stopAnimating()
                cell.goImageView.isHidden = false
                cell.goImageView.image = generalData.syncStatus.image
            case .none:
                cell.optionLabel.text = subsection.name
                cell.goImageView.isHidden = true
                cell.loader.stopAnimating()
                cell.loader.isHidden = true
            case .syncing:
                cell.goImageView.isHidden = true
                cell.loader.isHidden = false
                cell.loader.startAnimating()
            }
            return cell
        case .preview:
            let defaults = CriptextDefaults()
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralSwitch") as! GeneralSwitchTableViewCell
            cell.optionLabel.text = subsection.name
            cell.availableSwitch.isOn = !defaults.previewDisable
            cell.switchToggle = { isOn in
                defaults.previewDisable = !isOn
            }
            return cell
        case .night:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralSwitch") as! GeneralSwitchTableViewCell
            cell.optionLabel.text = subsection.name
            cell.availableSwitch.isOn = ThemeManager.shared.theme.name == "Dark"
            cell.switchToggle = { isOn in
                ThemeManager.shared.swapTheme(theme: isOn ? Theme.dark() : Theme.init())
                let defaults = CriptextDefaults()
                defaults.themeMode = ThemeManager.shared.theme.name
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
            cell.optionLabel.textColor = theme.mainText
            cell.optionLabel.text = subsection.name
            cell.goImageView.isHidden = false
            cell.messageLabel.text = ""
            cell.loader.stopAnimating()
            cell.loader.isHidden = true
            return cell
        }
    }
    
    func renderAboutCells(subsection: Section.SubSection) -> GeneralTapTableCellView {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
        cell.messageLabel.text = ""
        cell.loader.isHidden = true
        cell.goImageView.isHidden = false
        cell.optionLabel.textColor = theme.mainText
        cell.optionLabel.text = subsection.name
        return cell
    }
    
    func renderVersionCells() -> GeneralVersionTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralVersion") as! GeneralVersionTableViewCell
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        cell.versionLabel.text = "v.\(appVersionString)"
        return cell
    }
    
    func showManualSyncWarning() {
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("SYNC_WARNING")
        let attributedText = NSMutableAttributedString(string: String.localize("SYNC_WARNING_1"), attributes: [.font: Font.regular.size(15)!])
        attributedText.append(NSAttributedString(string: String.localize("SYNC_WARNING_2"), attributes: [.font: Font.bold.size(15)!]))
        popover.attributedMessage = attributedText
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("CONTINUE")
        popover.onResponse = { [weak self] accept in
            guard accept else {
                return
            }
            self?.showManualSyncPopup()
        }
        self.presentPopover(popover: popover, height: 270)
    }
    
    func showManualSyncPopup() {
        let popover = ManualSyncUIPopover()
        popover.myAccount = self.myAccount
        popover.onAccept = { [weak self] acceptData in
            self?.goToManualSync(acceptData: acceptData)
        }
        self.presentPopover(popover: popover, height: 350)
    }
    
    func goToDevices() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let devicesVC = storyboard.instantiateViewController(withIdentifier: "settingsDevicesViewController") as! SettingsDevicesViewController
        devicesVC.deviceData = devicesData
        devicesVC.myAccount = myAccount
        self.navigationController?.pushViewController(devicesVC, animated: true)
    }
    
    func goToLabels() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let labelsVC = storyboard.instantiateViewController(withIdentifier: "settingsLabelsViewController") as! SettingsLabelsViewController
        labelsVC.myAccount = myAccount
        self.navigationController?.pushViewController(labelsVC, animated: true)
    }
    
    func goToManualSync(acceptData: AcceptData) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "manualSyncViewController") as! ManualSyncViewController
        linkDeviceVC.acceptData = acceptData
        linkDeviceVC.myAccount = myAccount
        self.getTopView().presentedViewController?.dismiss(animated: false, completion: nil)
        self.getTopView().present(linkDeviceVC, animated: true, completion: nil)
    }
    
    func syncContacts(indexPath: IndexPath){
        generalData.syncStatus = .syncing
        tableView.reloadData()
        let syncContactsTask = RetrieveContactsTask(username: myAccount.username)
        syncContactsTask.start { [weak self] (success) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.generalData.syncStatus = success ? .success : .fail
            weakSelf.tableView.reloadData()
        }
    }
    
    func goToPrivacyAndSecurity(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let securityVC = storyboard.instantiateViewController(withIdentifier: "securityPrivacyViewController") as! SecurityPrivacyViewController
        securityVC.generalData = self.generalData
        securityVC.myAccount = self.myAccount
        securityVC.isPinControl = false
        self.navigationController?.pushViewController(securityVC, animated: true)
    }
    
    func goToPinLock(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let securityVC = storyboard.instantiateViewController(withIdentifier: "securityPrivacyViewController") as! SecurityPrivacyViewController
        securityVC.generalData = self.generalData
        securityVC.myAccount = self.myAccount
        securityVC.isPinControl = true
        self.navigationController?.pushViewController(securityVC, animated: true)
    }
    
    func goToProfile(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let profileVC = storyboard.instantiateViewController(withIdentifier: "profileEditorView") as! ProfileEditorViewController
        profileVC.generalData = self.generalData
        profileVC.devicesData = self.devicesData
        profileVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func goToUrl(url: String){
        let svc = SFSafariViewController(url: URL(string: url)!)
        self.present(svc, animated: true, completion: nil)
    }
}

extension SettingsGeneralViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus[sections[section]]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let subsection = menus[sections[indexPath.section]]![indexPath.row]
        switch(sections[indexPath.section]){
        case .account:
            return renderAccountCells(subsection: subsection)
        case .general:
            return renderGeneralCells(subsection: subsection)
        case .about:
            return renderAboutCells(subsection: subsection)
        default:
            return renderVersionCells()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != SECTION_VERSION else {
            return nil
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralHeader") as! GeneralHeaderTableViewCell
        let mySection = sections[section]
        if mySection == .account {
            cell.titleLabel.text = myAccount.email.uppercased()
        } else {
            cell.titleLabel.text = mySection.name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section != SECTION_VERSION ? ROW_HEIGHT : 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let subsection = menus[sections[indexPath.section]]![indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        switch(subsection){
        case .account:
            goToProfile()
        case .privacy:
            goToPrivacyAndSecurity()
        case .devices:
            goToDevices()
        case .labels:
            goToLabels()
        case .manualSync:
            showManualSyncWarning()
        case .pin:
            goToPinLock()
        case .faq:
            goToUrl(url: "https://criptext.com/\(Env.language)/faq")
        case .policies:
            goToUrl(url: "https://criptext.com/\(Env.language)/privacy")
        case .terms:
            goToUrl(url: "https://criptext.com/\(Env.language)/terms")
        case .openSource:
            goToUrl(url: "https://criptext.com/\(Env.language)/open-source-ios")
        default:
            break
        }
        
    }
}

extension SettingsGeneralViewController: CustomTabsChildController {
    func reloadView() {
        applyTheme()
        tableView.reloadData()
    }
}

extension SettingsGeneralViewController: ThemeDelegate {
    func swapTheme(_ theme: Theme) {
        applyTheme()
        self.tableView.reloadData()
    }
}
