//
//  SettingsDevicesViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SettingsDevicesViewController: UITableViewController {
    var myAccount: Account!
    var deviceData: DeviceSettingsData!
    var devices: [Device] {
        return deviceData.devices
    }
    
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
        cell.delegate = self
        cell.deviceImageView.image = Device.Kind(rawValue: device.type)! != .pc ? #imageLiteral(resourceName: "device-mobile") : #imageLiteral(resourceName: "device-desktop")
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

extension SettingsDevicesViewController: CustomTabsChildController {
    func reloadView() {
        tableView.reloadData()
    }
}

extension SettingsDevicesViewController: DeviceTableViewCellDelegate {
    func tableViewCellDidLongPress(_ cell: SettingsDeviceTableViewCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        let device = devices[indexPath.row]
        presentRemoveDevicePopover(device: device)
    }
    
    func presentRemoveDevicePopover(device: Device){
        let popoverHeight = 300
        let removeDevicePopover = RemoveDeviceUIPopover()
        removeDevicePopover.device = device
        removeDevicePopover.myAccount = myAccount
        guard let tabsController = self.tabsController else {
            self.presentPopover(popover: removeDevicePopover, height: popoverHeight)
            return
        }
        tabsController.presentPopover(popover: removeDevicePopover, height: popoverHeight)
    }
}
