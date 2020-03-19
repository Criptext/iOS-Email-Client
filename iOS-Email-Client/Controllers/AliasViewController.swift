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
    var aliasData: AliasSettingsData!
    var domains: [String] {
        return aliasData.domainAndAliasData.map { $0.key }
    }
    var table: [String : [Alias]] {
        return aliasData.domainAndAliasData
    }
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("ALIASES").capitalized
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icHelp").tint(with: .white), style: .plain, target: self, action: #selector(showInfo))
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.applyTheme()
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
}

extension AliasViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return domains.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(domains.count == 0 || section == domains.count) {
            return 0
        } else {
            return table[domains[section]]!.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(section == domains.count){
            let cell = tableView.dequeueReusableCell(withIdentifier: "aliasAddCell") as! AddAliasTableViewCell
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralHeader") as! GeneralHeaderTableViewCell
            let mySection = domains[section]
            cell.titleLabel.text = mySection
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let alias = table[domains[indexPath.section]]![indexPath.row]
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
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66.0
    }
}

extension AliasViewController: CustomTabsChildController {
    func reloadView() {
        self.applyTheme()
        tableView.reloadData()
    }
}

extension AliasViewController: AddAliasTableViewCellDelegate {
    func tableViewCellDidLongPress(_ cell: AddAliasTableViewCell) {
        let popoverHeight = 350
        let addAliasPopover = AddAliasUIPopover()
        addAliasPopover.myAccount = myAccount
        addAliasPopover.domains = domains.map { "@\($0)" }
        addAliasPopover.onSuccess = { [weak self] alias in
            DBManager.store(alias)
            let domainName = alias.domainName == nil ? Env.plainDomain : alias.domainName!
            self?.aliasData.domainAndAliasData[domainName]?.append(alias)
        }
        guard let tabsController = self.tabsController else {
            self.presentPopover(popover: addAliasPopover, height: popoverHeight)
            return
        }
        tabsController.presentPopover(popover: addAliasPopover, height: popoverHeight)
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
        guard let index = aliasData.domainAndAliasData[domain]?.firstIndex(where: {$0.rowId == aliasId}),
            let sectionIndex = domains.firstIndex(of: domain) else {
            return
        }
        aliasData.domainAndAliasData[domain]!.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: sectionIndex)], with: .automatic)
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
