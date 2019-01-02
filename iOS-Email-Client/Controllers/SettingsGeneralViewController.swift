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

class SettingsGeneralViewController: UITableViewController{
    
    internal enum Section {
        case account
        case about
        case version
        case appearance
        
        var name: String {
            switch(self){
            case .account:
                return String.localize("ACCOUNT")
            case .appearance:
                return String.localize("APPEARANCE")
            case .about:
                return String.localize("ABOUT")
            case .version:
                return String.localize("VERSION")
            }
        }
        
        enum SubSection {
            case profile
            case signature
            case changePassword
            case twoFactor
            case recovery
            case syncContact
            case deleteAccount
            
            case privacy
            case terms
            case openSource
            case logout
            
            case night
            
            case privacySecurity
            
            case version
            
            var name: String {
                switch(self){
                case .syncContact:
                    return String.localize("SYNC_PHONEBOOK")
                case .profile:
                    return String.localize("PROFILE")
                case .signature:
                    return String.localize("SIGNATURE")
                case .changePassword:
                    return String.localize("CHANGE_PASS")
                case .deleteAccount:
                    return String.localize("DELETE_ACCOUNT")
                case .twoFactor:
                    return String.localize("TWO_FACTOR")
                case .recovery:
                    return String.localize("RECOVERY_EMAIL")
                case .privacy:
                    return String.localize("POLICY")
                case .terms:
                    return String.localize("TERMS")
                case .openSource:
                    return String.localize("OPEN_LIBS")
                case .logout:
                    return String.localize("SIGNOUT")
                case .privacySecurity:
                    return String.localize("PRIVACY_SECURITY")
                case .version:
                    return String.localize("VERSION")
                case .night:
                    return String.localize("NIGHT_MODE")
                }
            }
        }
    }
    
    let SECTION_VERSION = 3
    let ROW_HEIGHT: CGFloat = 40.0
    let sections = [.account, .appearance, .about, .version] as [Section]
    let menus = [
        .account: [.profile, .signature, .changePassword, .recovery, .twoFactor, .privacySecurity, .syncContact],
        .about: [.privacy, .terms, .openSource, .logout, .deleteAccount],
        .appearance: [.night],
        .version : [.version]] as [Section: [Section.SubSection]
    ]
    var generalData: GeneralSettingsData!
    var myAccount : Account!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        self.applyTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus[sections[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let subsection = menus[sections[indexPath.section]]![indexPath.row]
        switch(sections[indexPath.section]){
        case .account:
            return renderAccountCells(subsection: subsection)
        case .about:
            return renderAboutCells(subsection: subsection)
        case .appearance:
            return renderAppearanceCells(subsection: subsection)
        default:
            return renderVersionCells()
        }
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
        switch(subsection){
        case .recovery:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
            cell.optionLabel.textColor = theme.mainText
            cell.optionLabel.text = subsection.name
            cell.messageLabel.text = generalData.recoveryEmailStatus.description
            cell.messageLabel.textColor = generalData.recoveryEmailStatus.color
            guard generalData.recoveryEmail != nil else {
                cell.loader.startAnimating()
                cell.loader.isHidden = false
                cell.goImageView.isHidden = true
                return cell
            }
            cell.loader.stopAnimating()
            cell.loader.isHidden = true
            cell.goImageView.isHidden = false
            return cell
        case .twoFactor:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralSwitch") as! GeneralSwitchTableViewCell
            cell.optionLabel.text = subsection.name
            cell.availableSwitch.isOn = generalData.isTwoFactor
            cell.switchToggle = { isOn in
                self.setTwoFactor(enable: isOn)
            }
            return cell
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
    
    func renderAppearanceCells(subsection: Section.SubSection) -> UITableViewCell {
        switch(subsection){
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralSwitch") as! GeneralSwitchTableViewCell
            cell.optionLabel.text = subsection.name
            cell.availableSwitch.isOn = ThemeManager.shared.theme.name == "Dark"
            cell.switchToggle = { isOn in
                ThemeManager.shared.swapTheme(theme: isOn ? Theme.dark() : Theme.init())
                let defaults = CriptextDefaults()
                defaults.themeMode = ThemeManager.shared.theme.name
            }
            return cell
        }
    }
    
    func renderAboutCells(subsection: Section.SubSection) -> GeneralTapTableCellView {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
        cell.messageLabel.text = ""
        cell.loader.isHidden = true
        cell.goImageView.isHidden = subsection == .deleteAccount || subsection == .logout
        cell.optionLabel.textColor = subsection == .deleteAccount ? theme.alert : theme.mainText
        cell.optionLabel.text = subsection.name
        return cell
    }
    
    func renderVersionCells() -> GeneralVersionTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralVersion") as! GeneralVersionTableViewCell
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        cell.versionLabel.text = "v.\(appVersionString)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != SECTION_VERSION else {
            return nil
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralHeader") as! GeneralHeaderTableViewCell
        cell.titleLabel.text = sections[section].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section != SECTION_VERSION ? ROW_HEIGHT : 0.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let subsection = menus[sections[indexPath.section]]![indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        switch(subsection){
        case .profile:
            presentNamePopover()
        case .changePassword:
            goToChangePassword()
        case .signature:
            goToSignature()
        case .privacy:
            goToUrl(url: "https://criptext.com/\(Env.language)/privacy")
        case .terms:
            goToUrl(url: "https://criptext.com/\(Env.language)/terms")
        case .openSource:
            goToUrl(url: "https://criptext.com/\(Env.language)/open-source-ios")
        case .logout:
            guard let customTabsVC = self.tabsController as? CustomTabsController,
                customTabsVC.devicesData.devices.count <= 1 && generalData.isTwoFactor else {
                showLogout()
                return
            }
            showWarningLogout()
        case .deleteAccount:
            showDeleteAccount()
        case .recovery:
            goToRecoveryEmail()
        case .privacySecurity:
            goToPrivacyAndSecurity()
        case .syncContact:
            guard generalData.syncStatus != .syncing else {
                break
            }
            syncContacts(indexPath: indexPath)
        default:
            break
        }
        
    }
    
    func syncContacts(indexPath: IndexPath){
        generalData.syncStatus = .syncing
        tableView.reloadData()
        let syncContactsTask = RetrieveContactsTask()
        syncContactsTask.start { [weak self] (success) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.generalData.syncStatus = success ? .success : .fail
            weakSelf.tableView.reloadData()
        }
    }
    
    func showLogout(){
        let logoutPopover = GenericDualAnswerUIPopover()
        logoutPopover.initialTitle = String.localize("SIGNOUT")
        logoutPopover.initialMessage = String.localize("Q_SURE_LOGOUT")
        logoutPopover.leftOption = String.localize("CANCEL")
        logoutPopover.rightOption = String.localize("YES")
        logoutPopover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            weakSelf.confirmLogout()
        }
        self.presentPopover(popover: logoutPopover, height: 175)
    }
    
    func showDeleteAccount(){
        let passwordPopover = PasswordUIPopover()
        passwordPopover.answerShouldDismiss = false
        passwordPopover.initialTitle = String.localize("DELETE_ACCOUNT")
        let attrRegularText = NSMutableAttributedString(string: String.localize("DELETING_ACCOUNT"), attributes: [NSAttributedString.Key.font: Font.regular.size(14)!, NSAttributedString.Key.foregroundColor: UIColor.black])
        let attrBoldText = NSMutableAttributedString(string: String.localize("DELETE_WILL_ERASE"), attributes: [NSAttributedString.Key.font: Font.bold.size(14)!, NSAttributedString.Key.foregroundColor: UIColor.black])
        let attrRegularText2 = NSMutableAttributedString(string: String.localize("DELETE_NO_LONGER"), attributes: [NSAttributedString.Key.font: Font.regular.size(14)!, NSAttributedString.Key.foregroundColor: UIColor.black])
        attrRegularText.append(attrBoldText)
        attrRegularText.append(attrRegularText2)
        passwordPopover.initialAttrMessage = attrRegularText
        passwordPopover.onOkPress = { [weak self] pass in
            guard let weakSelf = self else {
                return
            }
            weakSelf.deleteAccount(password: pass)
        }
        self.presentPopover(popover: passwordPopover, height: 260)
    }
    
    func deleteAccount(password: String){
        APIManager.deleteAccount(password: password.sha256()!, account: self.myAccount, completion: { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            if case .BadRequest = responseData {
                if let popover = weakSelf.presentedViewController as? PasswordUIPopover {
                    popover.dismiss(animated: false, completion: nil)
                }
                weakSelf.showAlert(String.localize("DELETE_ACCOUNT_FAILED"), message: String.localize("WRONG_PASS_RETRY"), style: .alert)
                return
            }
            guard case .Success = responseData,
                let delegate = UIApplication.shared.delegate as? AppDelegate else {
                    if let popover = weakSelf.presentedViewController as? PasswordUIPopover {
                        popover.dismiss(animated: false, completion: nil)
                    }
                    weakSelf.showAlert(String.localize("DELETE_ACCOUNT_FAILED"), message: String.localize("UNABLE_DELETE_ACCOUNT"), style: .alert)
                return
            }
            delegate.logout(manually: false, message: String.localize("DELETE_ACCOUNT_SUCCESS"))
        })
    }
    
    func showWarningLogout() {
        let logoutPopover = GenericDualAnswerUIPopover()
        logoutPopover.initialTitle = String.localize("WARNING")
        logoutPopover.initialMessage = String.localize("Q_SIGNOUT_2FA")
        logoutPopover.leftOption = String.localize("CANCEL")
        logoutPopover.rightOption = String.localize("YES")
        logoutPopover.onResponse = { accept in
            guard accept else {
                return
            }
            self.confirmLogout()
        }
        self.presentPopover(popover: logoutPopover, height: 223)
    }
    
    func confirmLogout(){
        APIManager.logout(account: myAccount) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("SIGNOUT_ERROR"), message: String.localize("UNABLE_SIGNOUT"), style: .alert)
                return
            }
            self.logout(manually: true)
        }
    }
    
    func goToRecoveryEmail(){
        guard generalData.recoveryEmail != nil else {
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let recoveryVC = storyboard.instantiateViewController(withIdentifier: "recoveryEmailViewController") as! RecoveryEmailViewController
        recoveryVC.generalData = self.generalData
        recoveryVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(recoveryVC, animated: true)
    }
    
    func goToChangePassword(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let changePassVC = storyboard.instantiateViewController(withIdentifier: "changePassViewController") as! ChangePassViewController
        changePassVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(changePassVC, animated: true)
    }
    
    func goToPrivacyAndSecurity(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let securityVC = storyboard.instantiateViewController(withIdentifier: "securityPrivacyViewController") as! SecurityPrivacyViewController
        securityVC.generalData = self.generalData
        securityVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(securityVC, animated: true)
    }
    
    func goToSignature(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signatureVC = storyboard.instantiateViewController(withIdentifier: "signatureEditorViewController") as! SignatureEditorViewController
        signatureVC.myAccount = myAccount
        self.navigationController?.pushViewController(signatureVC, animated: true)
    }
    
    func presentNamePopover(){
        let changeNamePopover = SingleTextInputViewController()
        changeNamePopover.myTitle = String.localize("CHANGE_NAME")
        changeNamePopover.initInputText = self.myAccount.name
        changeNamePopover.onOk = { text in
            self.changeProfileName(name: text)
        }
        self.presentPopover(popover: changeNamePopover, height: Constants.singleTextPopoverHeight)
    }
    
    func goToUrl(url: String){
        print(url)
        let svc = SFSafariViewController(url: URL(string: url)!)
        self.present(svc, animated: true, completion: nil)
    }
    
    func changeProfileName(name: String){
        let params = EventData.Peer.NameChanged(name: name)
        APIManager.updateName(name: name, account: myAccount) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("SOMETHING_WRONG"), message: String.localize("UNABLE_UPDATE_PROFILE"), style: .alert)
                return
            }
            DBManager.update(account: self.myAccount, name: name)
            DBManager.createQueueItem(params: ["cmd": Event.Peer.changeName.rawValue, "params": params.asDictionary()])
        }
    }
    
    func setTwoFactor(enable: Bool){
        guard !enable || generalData.recoveryEmailStatus == .verified else {
            presentRecoveryPopover()
            self.reloadView()
            return
        }
        let initialValue = self.generalData.isTwoFactor
        self.generalData.isTwoFactor = enable
        APIManager.setTwoFactor(isOn: enable, account: myAccount) { (responseData) in
            if case .Conflicts = responseData {
                self.presentRecoveryPopover()
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("SOMETHING_WRONG"), message: "\(String.localize("UNABLE_TO")) \(enable ? String.localize("ENABLE") : String.localize("DISABLE")) \(String.localize("TWO_FACTOR_RETRY"))", style: .alert)
                self.generalData.isTwoFactor = initialValue
                self.reloadView()
                return
            }
            if (self.generalData.isTwoFactor) {
                self.presentTwoFactorPopover()
            }
        }
    }
    
    func presentRecoveryPopover() {
        let popover = GenericAlertUIPopover()
        let attributedRegular = NSMutableAttributedString(string: String.localize("TO_ENABLE_2FA_1"), attributes: [NSAttributedStringKey.font: Font.regular.size(15)!])
        let attributedSemibold = NSAttributedString(string: String.localize("TO_ENABLE_2FA_2"), attributes: [NSAttributedStringKey.font: Font.semibold.size(15)!])
        attributedRegular.append(attributedSemibold)
        popover.myTitle = String.localize("RECOVERY_NOT_SET")
        popover.myAttributedMessage = attributedRegular
        popover.myButton = String.localize("GOT_IT")
        self.presentPopover(popover: popover, height: 310)
    }
    
    func presentTwoFactorPopover() {
        let popover = GenericAlertUIPopover()
        popover.myTitle = String.localize("2FA_ENABLED")
        popover.myMessage = String.localize("NEXT_TIME_2FA")
        popover.myButton = String.localize("GOT_IT")
        self.presentPopover(popover: popover, height: 263)
    }
}

extension SettingsGeneralViewController: CustomTabsChildController {
    func reloadView() {
        applyTheme()
        tableView.reloadData()
    }
}
