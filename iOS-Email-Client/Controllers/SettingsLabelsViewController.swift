//
//  SettingsLabelsViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SettingsLabelsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var labels = [Label]()
    var myAccount: Account!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = String.localize("LABELS")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        labels.append(DBManager.getLabel(SystemLabel.starred.id)!)
        labels.append(contentsOf: DBManager.getUserLabels(account: myAccount, visible: false))
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UINib(nibName: "LabelsFooterTableViewCell", bundle: nil ), forHeaderFooterViewReuseIdentifier: "settingsAddLabel")
        self.tableView.register(UINib(nibName: "LabelsHeaderTableViewCell", bundle: nil ), forHeaderFooterViewReuseIdentifier: "settingsHeaderLabel")
        self.applyTheme()
        definesPresentationContext = true
    }
    
    func applyTheme() {
        let attributedTitle = NSAttributedString(string: String.localize("LABELS"), attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("LABELS"), attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        tableView.backgroundColor = theme.overallBackground
        self.view.backgroundColor = theme.overallBackground
        tableView.separatorColor = theme.separator
    }
    
    func presentPopover(){
        let theme: Theme = ThemeManager.shared.theme
        let parentView = (tabsController?.view ?? self.view)!
        let changeNamePopover = SingleTextInputViewController()
        changeNamePopover.myTitle = String.localize("ADD_LABEL")
        changeNamePopover.onOk = { [weak self] text in
            self?.createLabel(text: text)
        }
        changeNamePopover.preferredContentSize = CGSize(width: Constants.popoverWidth, height: Constants.singleTextPopoverHeight)
        changeNamePopover.popoverPresentationController?.sourceView = parentView
        changeNamePopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: parentView.frame.size.width, height: parentView.frame.size.height)
        changeNamePopover.popoverPresentationController?.permittedArrowDirections = []
        changeNamePopover.popoverPresentationController?.backgroundColor = theme.overallBackground
        self.present(changeNamePopover, animated: true)
    }
    
    func createLabel(text: String){
        let labelText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existingLabel = DBManager.getLabel(text: labelText) {
            self.showAlert(String.localize("REPEATED_LABEL"), message: String.localize("LABEL_EXISTS", arguments: existingLabel.text), style: .alert)
            return
        }
        let label = Label(labelText)
        label.account = myAccount
        DBManager.store(label, incrementId: true)
        self.labels.append(label)
        self.tableView.insertRows(at: [IndexPath(row: self.labels.count - 1, section: 0)], with: .automatic)
        let params = EventData.Peer.NewLabel(text: label.text, color: label.color, uuid: label.uuid)
        DBManager.createQueueItem(params: ["cmd": Event.Peer.newLabel.rawValue, "params": params.asDictionary()], account: myAccount)
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
}

extension SettingsLabelsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let label = labels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsLabelCell") as! LabelsLabelTableViewCell
        cell.fillFields(label: label)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "settingsAddLabel") as! LabelsFooterViewCell
        cell.onTapCell = { [weak self] in
            self?.presentPopover()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "settingsHeaderLabel")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let label = labels[indexPath.row]
        guard label.id != SystemLabel.starred.id else {
            return
        }
        DBManager.updateLabel(label, visible: !label.visible)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension SettingsLabelsViewController: CustomTabsChildController {
    func reloadView() {
        self.applyTheme()
        tableView.reloadData()
    }
}

extension SettingsLabelsViewController: UIGestureRecognizerDelegate {
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
