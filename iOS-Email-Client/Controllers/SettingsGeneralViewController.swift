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

protocol SettingsRefresher: class {
    func updateView()
}

class SettingsGeneralViewController: UIViewController{
    
    internal enum Section {
        case account
        case addresses
        case general
        case support
        case about
        case version
        
        var name: String {
            switch(self){
            case .account:
                return String.localize("ACCOUNT")
            case .addresses:
                return String.localize("ADDRESSES")
            case .general:
                return String.localize("GENERAL")
            case .support:
                return String.localize("SUPPORT").uppercased()
            case .about:
                return String.localize("ABOUT")
            case .version:
                return String.localize("VERSION")
            }
        }
        
        enum SubSection {
            case account
            case plus
            case privacy
            case devices
            case labels
            case manualSync
            case backup
            
            case addressManager
            
            case night
            case syncContact
            case preview
            case pin
            
            case reportBug
            case reportAbuse
            
            case faq
            case policies
            case terms
            case openSource
            
            case version
            
            var name: String {
                switch(self){
                case .backup:
                    return String.localize("BACKUP")
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
                case .plus:
                    return String.localize("JOIN_PLUS")
                case .devices:
                    return String.localize("DEVICES_OPTION")
                case .labels:
                    return String.localize("LABELS_OPTION")
                case .preview:
                    return String.localize("SHOW_PREVIEW")
                case .reportBug:
                    return String.localize("REPORT_BUG")
                case .reportAbuse:
                    return String.localize("REPORT_ABUSE")
                case .pin:
                    return String.localize("PIN_LOCK")
                case .faq:
                    return String.localize("FAQ")
                case .policies:
                    return String.localize("POLICY")
                case .addressManager:
                    return String.localize("ADDRESS_MANAGER")
                }
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    let STATUS_NOT_CONFIRMED = 0
    let SECTION_VERSION = 5
    let ROW_HEIGHT: CGFloat = 40.0
    var sections = [.account, .addresses, .general, .support, .about, .version] as [Section]
    var menus = [
        .account: [.account, .privacy, .devices, .labels, .manualSync, .backup, .plus],
        .addresses: [.addressManager],
        .general: [.night, .syncContact, .preview, .pin],
        .support: [.reportBug, .reportAbuse],
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
        
        if (myAccount.customerType == Constants.enterprise) {
            sections.remove(at: 1);
            menus.removeValue(forKey: .addresses)
            menus[.account]?.remove(at: 6)
        }
        
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
        APIManager.getSettings(token: myAccount.jwt) { (responseData) in
            if case .Removed = responseData {
                self.logout(account: self.myAccount, manually: false)
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case let .SuccessDictionary(settings) = responseData,
                let devices = settings["devices"] as? [[String: Any]],
                let addresses = settings["addresses"] as? [[String: Any]],
                let general = settings["general"] as? [String: Any] else {
                    return
            }
            self.parseAddresses(addresses: addresses)
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
            
            let customerType = general["customerType"] as! Int
            
            if (customerType != self.myAccount.customerType) {
                DBManager.update(account: self.myAccount, customerType: customerType)
            }
            
            if let blockRemoteContent = general["blockRemoteContent"] as? Int,
                (blockRemoteContent == 1 ? true : false) != self.myAccount.blockRemoteContent {
                DBManager.update(account: self.myAccount, blockContent: blockRemoteContent == 1 ? true : false )
            }
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
    
    func parseAddresses(addresses: [[String: Any]]) {
        let aliasesPairArray = addresses.map({aliasesDomainFromDictionary(data: $0, account: self.myAccount)})
        var ignoreDeleteAliasIds: [Int] = []
        var ignoreDeleteDomainNames: [String] = []
        var myDefaultAddressId: Int = 0
        for pair in aliasesPairArray {
            if pair.0.name != Env.plainDomain {
                if let existingDomain = DBManager.getCustomDomain(name: pair.0.name, account: myAccount) {
                    DBManager.update(customDomain: existingDomain, validated: pair.0.validated)
                } else {
                    DBManager.store(pair.0)
                }
            }
            ignoreDeleteDomainNames.append(pair.0.name)
            for alias in pair.1 {
                if let existingAlias = DBManager.getAlias(rowId: alias.rowId, account: self.myAccount) {
                    DBManager.update(alias: existingAlias, active: alias.active)
                } else {
                    DBManager.store(alias)
                }
                ignoreDeleteAliasIds.append(alias.rowId)
            }
            if let defaultAddressId = pair.2 {
                myDefaultAddressId = defaultAddressId
            }
        }
        if (myDefaultAddressId != self.myAccount.defaultAddressId) {
            DBManager.update(account: self.myAccount, defaultAddressId: myDefaultAddressId)
        }
        
        DBManager.deleteAlias(ignore: ignoreDeleteAliasIds, account: self.myAccount)
        DBManager.deleteCustomDomains(ignore: ignoreDeleteDomainNames, account: self.myAccount)
    }
    
    func aliasesDomainFromDictionary(data: [String: Any], account: Account) -> (CustomDomain, [Alias], Int?) {
        let aliases = data["aliases"] as! [[String: Any]]
        let domainData = data["domain"] as! [String: Any]
        let domainName = domainData["name"] as! String
        let domainVerified = domainData["confirmed"] as! Int
        
        let domain = CustomDomain()
        domain.name = domainName
        domain.validated = domainVerified == 1 ? true : false
        domain.account = account
        
        var defaultAddressId: Int? = nil
        let aliasesArray: [Alias] = aliases.map { aliasObj in
            let alias = Alias.aliasFromDictionary(aliasData: aliasObj, domainName: domainName, account: account)
            if let isDefault = aliasObj["default"] as? Int,
                isDefault == 1 {
                defaultAddressId = alias.rowId
            }
            return alias
        }
                
        return (domain, aliasesArray, defaultAddressId)
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
        case .plus:
            cell.optionLabel.text = Constants.isPlus(customerType: myAccount.customerType) ? String.localize("BILLING") : String.localize("JOIN_PLUS")
        default:
            cell.goImageView.isHidden = false
        }
        return cell
    }
    
    func renderAddressesCells(subsection: Section.SubSection) -> GeneralTapTableCellView {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
        cell.messageLabel.text = ""
        cell.loader.isHidden = true
        cell.goImageView.isHidden = false
        cell.optionLabel.textColor = theme.mainText
        cell.optionLabel.text = subsection.name
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
    
    func renderSupportCells(subsection: Section.SubSection) -> GeneralTapTableCellView {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
        cell.messageLabel.text = ""
        cell.loader.isHidden = true
        cell.goImageView.isHidden = false
        cell.optionLabel.textColor = theme.mainText
        cell.optionLabel.text = subsection.name
        return cell
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
        guard devicesData.devices.count != 0 && devicesData.devices.count > 1 else {
            let popover = GenericAlertUIPopover()
            popover.myButton = String.localize("OK")
            popover.myMessage = String.localize("NO_OTHER_DEVICE")
            popover.myTitle = String.localize("ODD")
            self.presentPopover(popover: popover, height: 200)
            return
        }
        
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("SYNC_WARNING")
        let attributedText = NSMutableAttributedString(string: String.localize("SYNC_WARNING_1"), attributes: [.font: Font.regular.size(15)!])
        attributedText.append(NSAttributedString(string: String.localize("SYNC_WARNING_2"), attributes: [.font: Font.bold.size(15)!]))
        popover.attributedMessage = attributedText
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("CONTINUE")
        popover.onResponse = { [weak self] accept in
            guard accept else {
                guard let weakSelf = self else {
                    return
                }
                APIManager.syncCancel(token: weakSelf.myAccount.jwt, completion: {_ in})
                return
            }
            self?.showManualSyncPopup()
        }
        self.presentPopover(popover: popover, height: 270)
    }
    
    func showManualSyncPopup() {
        let popover = ManualSyncUIPopover()
        popover.myAccount = self.myAccount
        popover.onAccept = { [weak self] acceptData, recipientId, domain in
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
    
    func goToBackup() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let backupVC = storyboard.instantiateViewController(withIdentifier: "backupViewController") as! BackupViewController
        backupVC.myAccount = myAccount
        
        self.navigationController?.pushViewController(backupVC, animated: true)
    }
    
    func goToCustomDomains() {
        let customDomains = DBManager.getCustomDomains(account: myAccount)
        if(customDomains.count > 0){
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let customDomainVC = storyboard.instantiateViewController(withIdentifier: "customDomainViewController") as! CustomDomainViewController
            customDomainVC.myAccount = myAccount
            customDomainVC.domains.append(contentsOf: customDomains)
            self.navigationController?.pushViewController(customDomainVC, animated: true)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let customEntryVC = storyboard.instantiateViewController(withIdentifier: "customDomainEntryViewController") as! CustomDomainEntryViewController
            customEntryVC.myAccount = myAccount
            
            self.navigationController?.pushViewController(customEntryVC, animated: true)
        }
    }
    
    func goToAliases() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let aliasVC = storyboard.instantiateViewController(withIdentifier: "aliasViewController") as! AliasViewController
        aliasVC.myAccount = myAccount
        self.navigationController?.pushViewController(aliasVC, animated: true)
    }
    
    func goToUpgradePlus() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let webviewVC = storyboard.instantiateViewController(withIdentifier: "plusviewcontroller") as! PlusViewController
        self.navigationController?.pushViewController(webviewVC, animated: true)
    }
    
    func goToAddresses() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let webviewVC = storyboard.instantiateViewController(withIdentifier: "membershipViewController") as! MembershipWebViewController
        webviewVC.delegate = self
        webviewVC.initialTitle = String.localize("ADDRESS_MANAGER")
        webviewVC.accountJWT = self.myAccount.jwt
        webviewVC.kind = .addresses
        self.navigationController?.pushViewController(webviewVC, animated: true)
    }
    
    func syncContacts(){
        generalData.syncStatus = .syncing
        tableView.reloadData()
        let syncContactsTask = RetrieveContactsTask(accountId: myAccount.compoundKey)
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
    
    func goToReportComposer(isPhishing: Bool){
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let supportContact = Contact()
        let composerData = ComposerData()
        if(!isPhishing){
            supportContact.displayName = "Criptext Support"
            supportContact.email = "support@criptext.com"
            composerData.initSubject = "Customer Support - iOS"
        } else {
            supportContact.displayName = "Criptext Report Abuse"
            supportContact.email = "abuse@criptext.com"
            composerData.initSubject = "Report Abuse - iOS"
        }
        composerData.initContent = "<br/><br/><span>\(String.localize("DONT_WRITE_BELOW"))</span><br/><span>***************************</span><br/><span>Version: \(appVersionString)</span><br/><span>Device: \(UIDevice.modelName) [\(systemIdentifier())]</span><br/><span>OS: \(UIDevice.current.systemVersion)</span>"
        composerData.initToContacts = [supportContact]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composerVC = navComposeVC.viewControllers.first as! ComposeViewController
        composerVC.composerData = composerData
        composerVC.delegate = self
        self.present(snackVC, animated: true, completion: { [weak self] in
            self?.navigationDrawerController?.closeLeftView()
        })
    }
}

extension SettingsGeneralViewController: MembershipWebViewControllerDelegate {
    func close() {
        
    }
}

extension SettingsGeneralViewController: ComposerSendMailDelegate {
    func newDraft(draft: Email) {
        self.showSendingSnackBar(message: String.localize("DRAFT_SAVED"), permanent: false)
    }
    
    func sendFailEmail(){
        guard let email = DBManager.getEmailFailed(account: self.myAccount) else {
            return
        }
        DBManager.updateEmail(email, status: .sending)
        let bodyFromFile = FileUtils.getBodyFromFile(account: myAccount, metadataKey: "\(email.key)")
        sendMail(email: email,
                 emailBody: bodyFromFile.isEmpty ? email.content : bodyFromFile,
                 password: nil)
    }
    
    func sendMail(email: Email, emailBody: String, password: String?) {
        showSendingSnackBar(message: String.localize("SENDING_MAIL"), permanent: true)
        reloadIfSentMailbox(email: email)
        let sendMailAsyncTask = SendMailAsyncTask(email: email, emailBody: emailBody, password: password)
        sendMailAsyncTask.start { [weak self] responseData in
            guard let weakSelf = self else {
                return
            }
            if case .Unauthorized = responseData {
                weakSelf.showSnackbar(String.localize("AUTH_ERROR_MESSAGE"), attributedText: nil, permanent: false)
                return
            }
            if case .Removed = responseData {
                weakSelf.logout(account: weakSelf.myAccount, manually: false)
                return
            }
            if case .Forbidden = responseData {
                weakSelf.showSnackbar(String.localize("EMAIL_FAILED"), attributedText: nil, permanent: false)
                weakSelf.presentPasswordPopover(myAccount: weakSelf.myAccount)
                return
            }
            if case let .Error(error) = responseData {
                weakSelf.showSnackbar("\(error.description). \(String.localize("RESENT_FUTURE"))", attributedText: nil, permanent: false)
                return
            }
            guard case let .SuccessInt(key) = responseData else {
                weakSelf.showSnackbar(String.localize("EMAIL_FAILED"), attributedText: nil, permanent: false)
                return
            }
            let sentEmail = DBManager.getMail(key: key, account: weakSelf.myAccount)
            guard sentEmail != nil else {
                weakSelf.showSendingSnackBar(message: String.localize("EMAIL_SENT"), permanent: false)
                return
            }
            let message = sentEmail!.secure ? String.localize("EMAIL_SENT_SECURE") : String.localize("EMAIL_SENT")
            weakSelf.showSendingSnackBar(message: message, permanent: false)
            weakSelf.sendFailEmail()
        }
    }
    
    func reloadIfSentMailbox(email: Email){
        
    }
    
    func showSendingSnackBar(message: String, permanent: Bool) {
        let fullString = NSMutableAttributedString(string: "")
        let attrs = [NSAttributedString.Key.font : Font.regular.size(15)!, NSAttributedString.Key.foregroundColor : UIColor.white]
        fullString.append(NSAttributedString(string: message, attributes: attrs))
        self.showSnackbar("", attributedText: fullString, permanent: permanent)
    }
    
    func deleteDraft(draftId: Int) {
        
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
        case .addresses:
            return renderAddressesCells(subsection: subsection)
        case .general:
            return renderGeneralCells(subsection: subsection)
        case .support:
            return renderSupportCells(subsection: subsection)
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
            cell.titleLabel.text = myAccount.isInvalidated ? "" : myAccount.email.uppercased()
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
        case .plus:
            goToUpgradePlus()
        case .privacy:
            goToPrivacyAndSecurity()
        case .devices:
            goToDevices()
        case .labels:
            goToLabels()
        case .manualSync:
            showManualSyncWarning()
        case .backup:
            goToBackup()
        case .addressManager:
            goToAddresses()
        case .syncContact:
            syncContacts()
        case .pin:
            goToPinLock()
        case .reportBug:
            goToReportComposer(isPhishing: false)
        case .reportAbuse:
            goToReportComposer(isPhishing: true)
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

extension SettingsGeneralViewController {
    func reloadView() {
        applyTheme()
        tableView.reloadData()
        if let childViews = self.navigationController?.children {
            for childView in childViews {
                guard let settingsRefresher = childView as? SettingsRefresher else {
                    continue
                }
                settingsRefresher.updateView()
            }
        }
    }
}

extension SettingsGeneralViewController: ThemeDelegate {
    func swapTheme(_ theme: Theme) {
        applyTheme()
        self.tableView.reloadData()
    }
}
