//
//  CustomTabsController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/24/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

protocol CustomTabsChildController {
    func reloadView()
}

class CustomTabsController: TabsController {
    let STATUS_NOT_CONFIRMED = 0
    var myAccount: Account!
    var devicesData = DeviceSettingsData()
    var generalData = GeneralSettingsData()
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ThemeManager.shared.addListener(id: "settings", delegate: self)
        self.devicesData.devices.append(Device.createActiveDevice(deviceId: myAccount.deviceId))
        self.navigationItem.title = String.localize("SETTINGS")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-rounded").tint(with: .white), style: .plain, target: self, action: #selector(dismissViewController))
        self.loadData()
        self.applyTheme()
    }
    
    func applyTheme() {
        tabBar.setLineColor(theme.criptextBlue, for: .selected)
        tabBar.contentView.backgroundColor = theme.background
    }
    
    func loadData(){
        let myDevice = Device.createActiveDevice(deviceId: myAccount.deviceId)
        APIManager.getSettings(account: myAccount) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case let .SuccessDictionary(settings) = responseData,
                let devices = settings["devices"] as? [[String: Any]],
                let general = settings["general"] as? [String: Any] else {
                return
            }
            let myDevices = devices.map({Device.fromDictionary(data: $0)}).filter({$0.id != myDevice.id}).sorted(by: {$0.safeDate > $1.safeDate})
            self.devicesData.devices.append(contentsOf: myDevices)
            let email = general["recoveryEmail"] as! String
            let status = general["recoveryEmailConfirmed"] as! Int
            let isTwoFactor = general["twoFactorAuth"] as! Int
            let hasEmailReceipts = general["trackEmailRead"] as! Int
            self.generalData.recoveryEmail = email
            self.generalData.recoveryEmailStatus = email.isEmpty ? .none : status == self.STATUS_NOT_CONFIRMED ? .pending : .verified
            self.generalData.isTwoFactor = isTwoFactor == 1 ? true : false
            self.generalData.hasEmailReceipts = hasEmailReceipts == 1 ? true : false
            self.reloadChildViews()
        }
    }
    
    func reloadChildViews(){
        self.navigationController?.childViewControllers.forEach({ (vc) in
            guard let childTabVC = vc as? CustomTabsChildController else {
                return
            }
            childTabVC.reloadView()
        })
        viewControllers.forEach { (vc) in
            guard let childTabVC = vc as? CustomTabsChildController else {
                return
            }
            childTabVC.reloadView()
        }
    }
    
    @objc func dismissViewController(){
        self.dismiss(animated: true, completion: nil)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        ThemeManager.shared.removeListener(id: "settings")
    }
}

extension CustomTabsController: LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = myAccount
        self.present(linkDeviceVC, animated: true, completion: nil)
    }
    func onCancelLinkDevice(linkData: LinkData) {
        if case .sync = linkData.kind {
            APIManager.syncDeny(randomId: linkData.randomId, account: myAccount, completion: {_ in })
        } else {
            APIManager.linkDeny(randomId: linkData.randomId, account: myAccount, completion: {_ in })
        }
    }
}

extension CustomTabsController: ThemeDelegate {
    func swapTheme(_ theme: Theme) {
        applyTheme()
        self.layoutSubviews()
        reloadChildViews()
    }
}
