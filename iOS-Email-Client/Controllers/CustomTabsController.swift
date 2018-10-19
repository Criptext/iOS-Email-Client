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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.devicesData.devices.append(Device.createActiveDevice(deviceId: myAccount.deviceId))
        self.navigationItem.title = "SETTINGS"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-rounded").tint(with: .white), style: .plain, target: self, action: #selector(dismissViewController))
        self.loadData()
    }
    
    func loadData(){
        let myDevice = Device.createActiveDevice(deviceId: myAccount.deviceId)
        APIManager.getSettings(token: myAccount.jwt) { (responseData) in
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
            self.generalData.recoveryEmail = email
            self.generalData.recoveryEmailStatus = email.isEmpty ? .none : status == self.STATUS_NOT_CONFIRMED ? .pending : .verified
            self.generalData.isTwoFactor = isTwoFactor == 1 ? true : false
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
        childViewControllers.forEach { (vc) in
            guard let childTabVC = vc as? CustomTabsChildController else {
                return
            }
            childTabVC.reloadView()
        }
    }
    
    @objc func dismissViewController(){
        self.dismiss(animated: true, completion: nil)
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
        APIManager.linkDeny(randomId: linkData.randomId, token: myAccount.jwt, completion: {_ in })
    }
}
