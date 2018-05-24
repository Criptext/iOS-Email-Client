//
//  SettingsGeneralViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class SettingsGeneralViewController: UITableViewController{
    let sections = ["", "ACCOUNT", "NOTIFICATIONS"] as [String]
    let menus = [
        "": ["Swipe Options"],
        "ACCOUNT": ["Profile Name", "Profile Photo", "Reset Password", "Recovery Email", "Signature"],
    "NOTIFICATIONS": ["Allow Notifications", "Sounds", "Badge App Icon"]] as [String: [String]]
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
        cell.optionLabel.text = text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let text = menus[sections[indexPath.section]]![indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        switch(text){
        case "Profile Name":
            presentPopover()
        case "Signature":
            goToSignature()
        default:
            break
        }
        
    }
    
    func goToSignature(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signatureVC = storyboard.instantiateViewController(withIdentifier: "signatureEditorViewController")
        
        self.navigationController?.pushViewController(signatureVC, animated: true)
    }
    
    func presentPopover(){
        let changeNamePopover = ProfileNameChangeViewController()
        changeNamePopover.currentName = myAccount.name
        changeNamePopover.preferredContentSize = CGSize(width: 270, height: 178)
        changeNamePopover.popoverPresentationController?.sourceView = self.view
        changeNamePopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        changeNamePopover.popoverPresentationController?.permittedArrowDirections = []
        changeNamePopover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(changeNamePopover, animated: true)
    }
    
}
