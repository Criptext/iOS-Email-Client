//
//  SettingsLabelsViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SettingsLabelsViewController: UITableViewController {
    var labels = [Label]()
    var myAccount: Account!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        labels.append(DBManager.getLabel(SystemLabel.starred.id)!)
        labels.append(contentsOf: DBManager.getLabels(type: "custom"))
        let attributedTitle = NSAttributedString(string: String.localize("LABELS"), attributes: [.font: Font.semibold.size(16.0)!])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        tabItem.setTabItemColor(.black, for: .normal)
        tabItem.setTabItemColor(.mainUI, for: .selected)
        
        self.tableView.register(UINib(nibName: "LabelsFooterTableViewCell", bundle: nil ), forHeaderFooterViewReuseIdentifier: "settingsAddLabel")
        self.tableView.register(UINib(nibName: "LabelsHeaderTableViewCell", bundle: nil ), forHeaderFooterViewReuseIdentifier: "settingsHeaderLabel")
        
        definesPresentationContext = true
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let label = labels[indexPath.row]
        let isDisabled = label.id == SystemLabel.starred.id
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsLabelCell") as! LabelsLabelTableViewCell
        
        cell.labelLabel.text = label.localized
        cell.checkMarkView.setChecked(label.visible, disabled: isDisabled)
        cell.colorDotsView.backgroundColor = UIColor(hex: label.color)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62.0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 55.0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "settingsAddLabel") as! LabelsFooterViewCell
        cell.onTapCell = { [weak self] in
            self?.presentPopover()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "settingsHeaderLabel")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let label = labels[indexPath.row]
        guard label.id != SystemLabel.starred.id else {
            return
        }
        DBManager.updateLabel(label, visible: !label.visible)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func presentPopover(){
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
        changeNamePopover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(changeNamePopover, animated: true)
    }
    
    func createLabel(text: String){
        let labelText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existingLabel = DBManager.getLabel(text: labelText) {
            self.showAlert(String.localize("REPEATED_LABEL"), message: String.localize("LABEL_EXISTS", arguments: existingLabel.text), style: .alert)
            return
        }
        let label = Label(labelText)
        DBManager.store(label, incrementId: true)
        self.labels.append(label)
        self.tableView.insertRows(at: [IndexPath(row: self.labels.count - 1, section: 0)], with: .automatic)
        let params = EventData.Peer.NewLabel(text: label.text, color: label.color)
        DBManager.createQueueItem(params: ["cmd": Event.Peer.newLabel.rawValue, "params": params.asDictionary()])
    }
}

extension SettingsLabelsViewController: CustomTabsChildController {
    func reloadView() {
    }
}
