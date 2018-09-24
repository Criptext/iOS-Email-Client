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
        let attributedTitle = NSAttributedString(string: "DEVICES", attributes: [.font: Font.semibold.size(16.0)!])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
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
        cell.deviceNameLabel.text = device.friendlyName
        cell.deviceLocationLabel.text = device.location
        cell.displayAsActive(device.active)
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
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        presentRemoveDevicePopover(device: device)
    }
    
    func presentRemoveDevicePopover(device: Device){
        let popoverHeight = 290
        let removeDevicePopover = RemoveDeviceUIPopover()
        removeDevicePopover.device = device
        removeDevicePopover.myAccount = myAccount
         removeDevicePopover.onSuccess = { [weak self] deviceId in
            self?.removeDevice(deviceId)
        }
        guard let tabsController = self.tabsController else {
            self.presentPopover(popover: removeDevicePopover, height: popoverHeight)
            return
        }
        tabsController.presentPopover(popover: removeDevicePopover, height: popoverHeight)
    }
    
    func removeDevice(_ deviceId: Int){
        guard let index = deviceData.devices.index(where: {$0.id == deviceId}) else {
            return
        }
        deviceData.devices.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
}
