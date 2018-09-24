//
//  LinkData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class LinkData {
    
    let deviceName: String
    let deviceType: Int
    let randomId: String
    
    init(deviceName: String, deviceType: Int, randomId: String) {
        self.deviceName = deviceName
        self.deviceType = deviceType
        self.randomId = randomId
    }
    
    class func fromDictionary(_ params: [String: Any]) -> LinkData? {
        guard let deviceInfo = params["newDeviceInfo"] as? [String: Any],
            let deviceName = deviceInfo["deviceFriendlyName"] as? String,
            let deviceType = deviceInfo["deviceType"] as? Int,
            let randomId = (deviceInfo["session"] as? [String: Any])?["randomId"] as? String else {
                return nil
        }
        return LinkData(deviceName: deviceName, deviceType: deviceType, randomId: randomId)
    }
}
