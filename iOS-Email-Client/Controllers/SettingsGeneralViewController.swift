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
    let sections = ["ACCOUNT", "ABOUT"] as [String]
    let menus = [
        "ACCOUNT": ["Profile Name", "Signature", "Recovery Email"],
    "ABOUT": ["Privacy Policy", "Terms of Service", "Open Source Libraries", "Logout", "Version"]] as [String: [String]]
    var generalData: GeneralSettingsData!
    var myAccount : Account!
    
    override func viewDidLoad() {
        tabItem.title = "General"
        tabItem.setTabItemColor(.black, for: .normal)
        tabItem.setTabItemColor(.mainUI, for: .selected)
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
        default:
            return renderAboutCells(text: text)
        }
    }
    
    func renderAccountCells(text: String) -> GeneralTapTableCellView {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
        cell.messageLabel.text = ""
        cell.goImageView.isHidden = false
        cell.optionLabel.text = text
        return cell
    }
    
    func renderAboutCells(text: String) -> GeneralTapTableCellView {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
        cell.messageLabel.text = ""
        
        guard text != "Version" else {
            cell.optionLabel.text = "Criptext Beta v.1.0.3"
            cell.goImageView.isHidden = true
            return cell
        }
        
        cell.goImageView.isHidden = false
        cell.optionLabel.text = text
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let text = menus[sections[indexPath.section]]![indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        switch(text){
        case "Profile Name":
            presentNamePopover()
        case "Signature":
            goToSignature()
        case "Privacy Policy":
            goToUrl(url: "https://criptext.com/privacy")
        case "Terms of Service":
            goToUrl(url: "https://criptext.com/terms")
        case "Open Source Libraries":
            goToUrl(url: "https://criptext.com/open-source-ios")
        case "Logout":
            logout()
        case "Recovery Email":
            goToRecoveryEmail()
        default:
            break
        }
        
    }
    
    func logout(){
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
        APIManager.removeDevice(deviceId: myAccount.deviceId, token: myAccount.jwt) { (error) in
            guard error == nil else {
                self.showAlert("Logout Error", message: "Unable to logout. Please try again", style: .alert)
                return
            }
            self.jumpToLogin()
        }
    }
    
    func jumpToLogin(){
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        APIManager.cancelAllRequests()
        WebSocketManager.sharedInstance.close()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "activeAccount")
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let initialVC = storyboard.instantiateInitialViewController()!
        present(initialVC, animated: true) { [weak self] in
            DBManager.signout()
            delegate.replaceRootViewController(initialVC)
            self?.removeFromParentViewController()
        }
    }
    
    func goToRecoveryEmail(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let recoveryVC = storyboard.instantiateViewController(withIdentifier: "recoveryEmailViewController") as! RecoveryEmailViewController
        recoveryVC.generalData = self.generalData
        recoveryVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(recoveryVC, animated: true)
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
        APIManager.updateName(name: name, token: myAccount.jwt) { (error) in
            guard error == nil else {
                self.showAlert("Something went wrong", message: "Unable to update Profile Name. Please try again", style: .alert)
                return
            }
              APIManager.postPeerEvent(["cmd": Event.Peer.changeName.rawValue, "params": params.asDictionary()], token: self.myAccount.jwt) { (error) in
                guard error == nil else {
                    self.showAlert("Something went wrong", message: "Unable to update Profile Name. Please try again", style: .alert)
                    return
                }
                DBManager.update(account: self.myAccount, name: name)
            }
        }
    }
    
}
