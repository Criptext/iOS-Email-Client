//
//  SettingsDevicesViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SettingsDevicesViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var myAccount: Account!
    var deviceData: DeviceSettingsData!
    var devices: [Device] {
        return deviceData.devices
    }
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("DEVICES")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.applyTheme()
    }
    
    func applyTheme() {
        let attributedTitle = NSAttributedString(string: String.localize("DEVICES"), attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("DEVICES"), attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        tableView.backgroundColor = theme.overallBackground
        self.view.backgroundColor = theme.overallBackground
        tableView.separatorColor = theme.separator
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
}

extension SettingsDevicesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = devices[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsDeviceCell") as! SettingsDeviceTableViewCell
        cell.delegate = self
        cell.setContent(device: device)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66.0
    }
}

extension SettingsDevicesViewController: CustomTabsChildController {
    func reloadView() {
        self.applyTheme()
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
        guard let index = deviceData.devices.firstIndex(where: {$0.id == deviceId}) else {
            return
        }
        deviceData.devices.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
}

extension SettingsDevicesViewController: UIGestureRecognizerDelegate {
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
