//
//  SettingsDevicesViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SettingsDevicesViewController: UITableViewController {
    
    let devices = DBManager.getDevices()
    
    override func viewDidLoad() {
        tabItem.title = "Devices"
        tabItem.setTabItemColor(.black, for: .normal)
        tabItem.setTabItemColor(.mainUI, for: .selected)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = devices[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsDeviceCell") as! SettingsDeviceTableViewCell
        
        cell.deviceImageView.image = device.mobile ? #imageLiteral(resourceName: "device-mobile") : #imageLiteral(resourceName: "device-desktop")
        cell.deviceNameLabel.text = device.name
        cell.deviceLocationLabel.text = device.location
        cell.currentDeviceLabel.isHidden = !device.active
        cell.deviceLocationLabel.isHidden = !device.active
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66.0
    }
    
}
