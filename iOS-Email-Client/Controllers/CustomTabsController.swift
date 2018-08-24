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
        APIManager.getSettings(token: myAccount.jwt) { (error, settings) in
            guard let mySettings = settings,
                let devices = mySettings["devices"] as? [[String: Any]],
                let recoveryData = mySettings["recoveryEmail"] as? [String: Any] else {
                return
            }
            
            for device in devices {
                let newDevice = Device.fromDictionary(data: device)
                guard !self.devicesData.devices.contains(where: {$0.id == newDevice.id && $0.active}) else {
                    continue
                }
                self.devicesData.devices.append(newDevice)
            }
            let email = recoveryData["address"] as! String
            let status = recoveryData["status"] as! Int
            self.generalData.recoveryEmail = email
            self.generalData.recoveryEmailStatus = email.isEmpty ? .none : status == self.STATUS_NOT_CONFIRMED ? .pending : .verified
            self.reloadChildViews()
        }
    }
    
    func reloadChildViews(){
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
