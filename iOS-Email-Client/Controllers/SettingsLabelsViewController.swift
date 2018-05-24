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
    
    override func viewDidLoad() {
        labels.append(contentsOf: DBManager.getLabels())
        tabItem.title = "Labels"
        tabItem.setTabItemColor(.black, for: .normal)
        tabItem.setTabItemColor(.mainUI, for: .selected)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let label = labels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsLabelCell") as! LabelsLabelTableViewCell
        
        cell.labelLabel.text = label.text
        cell.checkMarkView.setChecked(true)
        guard label.type == "custom" else {
            cell.colorDotsContainer.isHidden = true
            cell.checkMarkView.isHidden = true
            return cell
        }
        cell.checkMarkView.isHidden = false
        cell.colorDotsContainer.isHidden = false
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
        return tableView.dequeueReusableCell(withIdentifier: "settingsAddLabel")
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableCell(withIdentifier: "settingsLabelHeader")
    }
}
