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
        "ACCOUNT": ["Profile Name", "Signature"],
    "ABOUT": ["Privacy Policy", "Terms of Service", "Open Source Libraries", "Version"]] as [String: [String]]
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
        guard indexPath.section < 2 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralSwitch") as! GeneralSwitchTableViewCell
            cell.optionLabel.text = text
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
        cell.messageLabel.text = ""
        guard text != "Version" else {
            cell.optionLabel.text = "Criptext Beta V.0.1"
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
            presentPopover()
        case "Signature":
            goToSignature()
        case "Privacy Policy":
            goToUrl(url: "https://criptext.com/privacy")
        case "Terms of Service":
            goToUrl(url: "https://criptext.com/terms")
        case "Open Source Libraries":
            goToUrl(url: "https://criptext.com/open-source-libraries-ios")
        default:
            break
        }
        
    }
    
    func goToSignature(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signatureVC = storyboard.instantiateViewController(withIdentifier: "signatureEditorViewController") as! SignatureEditorViewController
        signatureVC.myAccount = myAccount
        self.navigationController?.pushViewController(signatureVC, animated: true)
    }
    
    func presentPopover(){
        let changeNamePopover = SingleTextInputViewController()
        changeNamePopover.myTitle = "Change Name"
        changeNamePopover.initInputText = self.myAccount.name
        changeNamePopover.onOk = { text in
            self.changeProfileName(name: text)
        }
        changeNamePopover.preferredContentSize = CGSize(width: Constants.popoverWidth, height: Constants.singleTextPopoverHeight)
        changeNamePopover.popoverPresentationController?.sourceView = self.view
        changeNamePopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        changeNamePopover.popoverPresentationController?.permittedArrowDirections = []
        changeNamePopover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(changeNamePopover, animated: true)
    }
    
    func goToUrl(url: String){
        let svc = SFSafariViewController(url: URL(string: url)!)
        self.present(svc, animated: true, completion: nil)
    }
    
    func changeProfileName(name: String){
        let params = EventData.Peer.NameChanged(recipientId: myAccount.username, name: name)
        APIManager.postPeerEvent(["cmd": Event.Peer.changeName.rawValue, "params": params.asDictionary()], token: myAccount.jwt) { (error) in
            guard error == nil else {
                self.showAlert("Something went wrong", message: "Unable to update Profile Name. Please try again", style: .alert)
                return
            }
            DBManager.update(account: self.myAccount, name: name)
        }
    }
    
}
