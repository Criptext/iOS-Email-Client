//
//  AliasViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/6/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class CustomDomainViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var myAccount: Account!
    var customDomainData: CustomDomainSettingsData!
    var domains: [CustomDomain] {
        return customDomainData.domains
    }
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("CUSTOM_DOMAIN").capitalized
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icHelp").tint(with: .white), style: .plain, target: self, action: #selector(showInfo))
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.applyTheme()
    }
    
    func applyTheme() {
        let attributedTitle = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        tableView.backgroundColor = theme.overallBackground
        self.view.backgroundColor = theme.overallBackground
        tableView.separatorColor = theme.separator
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    @objc func showInfo(){
        let popover = GenericAlertUIPopover()
        popover.myTitle = String.localize("CUSTOM_DOMAIN")
        popover.myMessage = String.localize("CUSTOM_DOMAIN_INFO_MESSAGE_1")
        self.presentPopover(popover: popover, height: 220)
    }
}

extension CustomDomainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return domains.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let domain = domains[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "customDomainCell") as! CustomDomainTableViewCell
        cell.delegate = self
        cell.setContent(customDomain: domain)
        return cell
    }
}

extension CustomDomainViewController: CustomTabsChildController {
    func reloadView() {
        self.applyTheme()
        tableView.reloadData()
    }
}


extension CustomDomainViewController: CustomDomainTableViewCellDelegate {
    func tableViewCellDidLongPress(_ cell: CustomDomainTableViewCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        let domain = domains[indexPath.row]
        presentRemoveCustomDomainPopover(customDomain: domain)
    }
    
    func presentRemoveCustomDomainPopover(customDomain: CustomDomain){
        let popoverHeight = 290
        let removeCustomDomainPopover = GenericDualAnswerUIPopover()
        removeCustomDomainPopover.title = String.localize("DELETE_DOMAIN")
        removeCustomDomainPopover.initialMessage = String.localize("DELETE_DOMAIN_MESSAGE")
        removeCustomDomainPopover.onResponse = { (doDelete) in
            if(doDelete){
                APIManager.deleteCustomDomain(customDomain: customDomain.name, token: self.myAccount.jwt) { (responseData) in
                    guard case .Success = responseData else {
                        self.showSnackbarMessage(message: String.localize("DELETE_DOMAIN_ERROR"), permanent: false)
                        return
                    }
                    self.removeCustomDomain(customDomain)
                    if(self.domains.count == 0) {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let entryCV = storyboard.instantiateViewController(withIdentifier: "customDomainEntryViewController") as! CustomDomainEntryViewController
                        entryCV.myAccount = self.myAccount
                        
                        self.navigationController?.pushViewController(entryCV, animated: true)
                    }
                }
            }
        }
        guard let tabsController = self.tabsController else {
            self.presentPopover(popover: removeCustomDomainPopover, height: popoverHeight)
            return
        }
        tabsController.presentPopover(popover: removeCustomDomainPopover, height: popoverHeight)
    }
    
    func removeCustomDomain(_ customDomain: CustomDomain){
        guard let index = customDomainData.domains.firstIndex(where: {$0.rowId == customDomain.rowId}) else {
            return
        }
        let domainName = customDomain.name == Env.plainDomain ? nil : customDomain.name
        DBManager.deleteCustomDomain(customDomain)
        DBManager.deleteAlias(domainName, account: myAccount)
        customDomainData.domains.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        self.showSnackbarMessage(message: String.localize("DELETE_DOMAIN_ERROR"), permanent: false)
    }
    
    func showSnackbarMessage(message: String, permanent: Bool) {
        let fullString = NSMutableAttributedString(string: "")
        let attrs = [NSAttributedString.Key.font : Font.regular.size(15)!, NSAttributedString.Key.foregroundColor : UIColor.white]
        fullString.append(NSAttributedString(string: message, attributes: attrs))
        self.showSnackbar("", attributedText: fullString, buttons: "", permanent: permanent)
    }
}

extension CustomDomainViewController: UIGestureRecognizerDelegate {
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
