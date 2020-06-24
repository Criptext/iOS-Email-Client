//
//  AliasViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/6/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class AliasViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var myAccount: Account!
    var domains: [String] = []
    var tableDomains: [String] = []
    var table: [String : [Alias]] = [:]
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("ALIASES").capitalized
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icHelp").tint(with: .white), style: .plain, target: self, action: #selector(showInfo))
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        self.loadAliasesAndCustomDomains()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.reloadData()
        self.applyTheme()
    }
    
    func loadAliasesAndCustomDomains() {
        let aliases = DBManager.getAliases(account: myAccount)
        let customDomains = DBManager.getVerifiedCustomDomains(account: myAccount)
        aliases.forEach { (alias) in
            let domain = "@\(alias.domain ?? Env.plainDomain)"
            if (table[domain] == nil) {
                tableDomains.append(domain)
                table[domain] = [Alias]()
            }
            table[domain]?.append(alias)
        }
        
        domains.append(Env.domain)
        domains.append(contentsOf: customDomains.map {"@\($0.name)"})
    }
    
    func applyTheme() {
        let attributedTitle = NSAttributedString(string: String.localize("ALIASES").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("ALIASES").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
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
        popover.myTitle = String.localize("ALIASES")
        popover.myMessage = String.localize("ALIASES_INFO_MESSAGE")
        self.presentPopover(popover: popover, height: 220)
    }
    
    func askUpgradePlus() {
        let popover = GetPlusUIPopover()
        popover.plusType = .alias
        popover.onResponse = { upgrade in
            if (upgrade) {
                self.goToUpgradePlus()
            }
        }
        self.presentPopover(popover: popover, height: 435)
    }
    
    func goToUpgradePlus() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let webviewVC = storyboard.instantiateViewController(withIdentifier: "plusviewcontroller") as! PlusViewController
        self.navigationController?.pushViewController(webviewVC, animated: true)
    }
}

extension AliasViewController: MembershipWebViewControllerDelegate {
    func close() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension AliasViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableDomains.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(section == table.keys.count) {
            return 0
        } else {
            return table[tableDomains[section]]!.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(section == table.keys.count){
            let cell = tableView.dequeueReusableCell(withIdentifier: "aliasAddCell") as! AddAliasTableViewCell
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralHeader") as! GeneralHeaderTableViewCell
            let mySection = tableDomains[section]
            cell.titleLabel.text = mySection
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mySection = tableDomains[indexPath.section]
        let alias = table[mySection]![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "aliasCell") as! AliasTableViewCell
        cell.delegate = self
        cell.setContent(alias: alias)
        cell.switchToggle = { isOn in
            APIManager.activateAlias(rowId: alias.rowId, activate: isOn, token: self.myAccount.jwt){ (responseData) in
                guard case .Success = responseData else {
                    cell.activeSwitch.isOn = !isOn
                    return
                }
                DBManager.update(alias: alias, active: isOn)
                self.tableView.reloadData()
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
}

extension AliasViewController: AddAliasTableViewCellDelegate {
    func tableViewCellDidLongPress(_ cell: AddAliasTableViewCell) {
        let popoverHeight = 350
        let addAliasPopover = AddAliasUIPopover()
        addAliasPopover.myAccount = myAccount
        addAliasPopover.domains = self.domains
        addAliasPopover.onSuccess = { [weak self] alias in
            self?.addAlias(alias)
        }
        guard let tabsController = self.tabsController else {
            self.presentPopover(popover: addAliasPopover, height: popoverHeight)
            return
        }
        tabsController.presentPopover(popover: addAliasPopover, height: popoverHeight)
    }
    
    func addAlias(_ alias: Alias) {
        DBManager.store(alias)
        let domainName = "@\(alias.domain ?? Env.plainDomain)"
        if (table[domainName] == nil) {
            tableDomains.append(domainName)
            table[domainName] = [Alias]()
        }
        table[domainName]?.append(alias)
        self.tableView.reloadData()
    }
}

extension AliasViewController: AliasTableViewCellDelegate {
    func tableViewCellDidLongPress(_ cell: AliasTableViewCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        let alias = table[domains[indexPath.section]]![indexPath.row]
        presentRemoveAliasPopover(alias: alias)
    }
    
    func presentRemoveAliasPopover(alias: Alias){
        let popoverHeight = 290
        let removeAliasPopover = RemoveAliasUIPopover()
        removeAliasPopover.alias = alias
        removeAliasPopover.myAccount = myAccount
        removeAliasPopover.onSuccess = { [weak self] domain, aliasId in
            self?.removeAlias(domain, aliasId: aliasId)
        }
        guard let tabsController = self.tabsController else {
            self.presentPopover(popover: removeAliasPopover, height: popoverHeight)
            return
        }
        tabsController.presentPopover(popover: removeAliasPopover, height: popoverHeight)
    }
    
    func removeAlias(_ domain: String, aliasId: Int){
        guard let domainIndex = tableDomains.firstIndex(where: {"@\(domain)" == $0}),
            let aliasIndex = table[tableDomains[domainIndex]]?.firstIndex(where: {$0.rowId == aliasId}) else {
            return
        }
        let alias = table[tableDomains[domainIndex]]![aliasIndex]
        let domainSelected = tableDomains[domainIndex]
        DBManager.deleteAlias(alias)
        table[domainSelected]?.remove(at: aliasIndex)
        if (table[domainSelected]!.count == 0) {
            tableDomains.remove(at: domainIndex)
            table.removeValue(forKey: domainSelected)
        }
        tableView.reloadData()
    }
}

extension AliasViewController: UIGestureRecognizerDelegate {
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
