//
//  SettingsDevicesViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SettingsDevicesViewController: UITableViewController {
    
    let devices = [["name": "Samsung Galaxy S8",
                    "location": "Guayaquil - 12 hours ago",
                    "active": true,
                    "mobile": true],
                   ["name": "Mac Book Pro",
                    "location": "Guayaquil - 12 hours ago",
                    "active": false,
                    "mobile": false],
                   ["name": "Iphone X",
                    "location": "Quito - 23 hours ago",
                    "active": false,
                    "mobile": true]]
    
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
        
        let name = device["name"] as! String
        let location = device["location"] as! String
        let active = device["active"] as! Bool
        let mobile = device["mobile"] as! Bool
        
        cell.deviceImageView.image = mobile ? #imageLiteral(resourceName: "device-mobile") : #imageLiteral(resourceName: "device-desktop")
        cell.deviceNameLabel.text = name
        cell.deviceLocationLabel.text = location
        cell.currentDeviceLabel.isHidden = !active
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66.0
    }
    
}
