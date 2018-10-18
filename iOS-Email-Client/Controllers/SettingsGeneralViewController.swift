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

class SettingsGeneralViewController: UITableViewController{
    let SECTION_VERSION = 2
    let ROW_HEIGHT: CGFloat = 40.0
    let sections = ["ACCOUNT", "ABOUT", "VERSION"] as [String]
    let menus = [
        "ACCOUNT": ["Profile", "Signature", "Change Password", "Recovery Email", "Two-factor Authentication"],
    "ABOUT": ["Privacy Policy", "Terms of Service", "Open Source Libraries", "Logout"],
    "VERSION": ["Version"]] as [String: [String]]
    var generalData: GeneralSettingsData!
    var myAccount : Account!
    
    override func viewDidLoad() {
        let attributedTitle = NSAttributedString(string: "GENERAL", attributes: [.font: Font.semibold.size(16.0)!])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        tabItem.setTabItemColor(.black, for: .normal)
        tabItem.setTabItemColor(.mainUI, for: .selected)
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
        let text = menus[sections[indexPath.section]]![indexPath.row]
        switch(indexPath.section){
        case 0:
            return renderAccountCells(text: text)
        case 1:
            return renderAboutCells(text: text)
        default:
            return renderVersionCells(text: text)
        }
    }
    
    func renderAccountCells(text: String) -> UITableViewCell {
        switch(text){
        case "Recovery Email":
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
            cell.optionLabel.text = text
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
        case "Two-factor Authentication":
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralSwitch") as! GeneralSwitchTableViewCell
            cell.optionLabel.text = text
            cell.availableSwitch.isOn = generalData.isTwoFactor
            cell.switchToggle = { isOn in
                self.setTwoFactor(enable: isOn)
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
            cell.optionLabel.text = text
            cell.goImageView.isHidden = false
            cell.messageLabel.text = ""
            cell.loader.stopAnimating()
            cell.loader.isHidden = true
            return cell
        }
    }
    
    func renderAboutCells(text: String) -> GeneralTapTableCellView {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
        cell.messageLabel.text = ""
        cell.loader.isHidden = true
        cell.goImageView.isHidden = false
        cell.optionLabel.text = text
        return cell
    }
    
    func renderVersionCells(text: String) -> GeneralVersionTableViewCell {
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
        cell.titleLabel.text = sections[section]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section != SECTION_VERSION ? ROW_HEIGHT : 0.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let text = menus[sections[indexPath.section]]![indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        switch(text){
        case "Profile":
            presentNamePopover()
        case "Change Password":
            goToChangePassword()
        case "Signature":
            goToSignature()
        case "Privacy Policy":
            goToUrl(url: "https://criptext.com/privacy")
        case "Terms of Service":
            goToUrl(url: "https://criptext.com/terms")
        case "Open Source Libraries":
            goToUrl(url: "https://criptext.com/open-source-ios")
        case "Logout":
            showLogout()
        case "Recovery Email":
            goToRecoveryEmail()
        default:
            break
        }
        
    }
    
    func showLogout(){
        let logoutPopover = LogoutPopoverViewController()
        logoutPopover.onTrigger = { accept in
            guard accept else {
                return
            }
            self.confirmLogout()
        }
        self.presentPopover(popover: logoutPopover, height: 245)
    }
    
    func confirmLogout(){
        APIManager.logout(token: myAccount.jwt) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case .Success = responseData else {
                self.showAlert("Logout Error", message: "Unable to logout. Please try again", style: .alert)
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
    
    func goToSignature(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signatureVC = storyboard.instantiateViewController(withIdentifier: "signatureEditorViewController") as! SignatureEditorViewController
        signatureVC.myAccount = myAccount
        self.navigationController?.pushViewController(signatureVC, animated: true)
    }
    
    func presentNamePopover(){
        let changeNamePopover = SingleTextInputViewController()
        changeNamePopover.myTitle = "Change Name"
        changeNamePopover.initInputText = self.myAccount.name
        changeNamePopover.onOk = { text in
            self.changeProfileName(name: text)
        }
        self.presentPopover(popover: changeNamePopover, height: Constants.singleTextPopoverHeight)
    }
    
    func goToUrl(url: String){
        let svc = SFSafariViewController(url: URL(string: url)!)
        self.present(svc, animated: true, completion: nil)
    }
    
    func changeProfileName(name: String){
        let params = EventData.Peer.NameChanged(name: name)
        APIManager.updateName(name: name, token: myAccount.jwt) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case .Success = responseData else {
                self.showAlert("Something went wrong", message: "Unable to update Profile Name. Please try again", style: .alert)
                return
            }
              APIManager.postPeerEvent(["cmd": Event.Peer.changeName.rawValue, "params": params.asDictionary()], token: self.myAccount.jwt) { (responseData) in
                if case .Unauthorized = responseData {
                    self.logout()
                    return
                }
                if case .Forbidden = responseData {
                    self.presentPasswordPopover(myAccount: self.myAccount)
                    return
                }
                guard case .Success = responseData else {
                    self.showAlert("Something went wrong", message: "Unable to update Profile Name. Please try again", style: .alert)
                    return
                }
                DBManager.update(account: self.myAccount, name: name)
            }
        }
    }
    
    func setTwoFactor(enable: Bool){
        let initialValue = self.generalData.isTwoFactor
        self.generalData.isTwoFactor = enable
        APIManager.setTwoFactor(isOn: enable, token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                self.showAlert("Something went wrong", message: "Unable to \(enable ? "enable" : "disable") two pass. Please try again", style: .alert)
                self.generalData.isTwoFactor = initialValue
                self.reloadView()
                return
            }
        }
    }
}

extension SettingsGeneralViewController: CustomTabsChildController {
    func reloadView() {
        tableView.reloadData()
    }
}
