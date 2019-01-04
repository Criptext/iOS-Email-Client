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
    let kind: Kind
    var deviceId: Int32? = nil
    var version: Int = 1
    
    init(deviceName: String, deviceType: Int, randomId: String, kind: Kind) {
        self.deviceName = deviceName
        self.deviceType = deviceType
        self.randomId = randomId
        self.kind = kind
    }
    
    class func fromDictionary(_ params: [String: Any], kind: Kind = .link) -> LinkData? {
        if case .sync = kind {
            guard let deviceInfo = params["requestingDeviceInfo"] as? [String: Any],
                let deviceName = deviceInfo["deviceFriendlyName"] as? String,
                let deviceType = deviceInfo["deviceType"] as? Int,
                let randomId = params["randomId"] as? String,
                let version = params["version"] as? Int,
                let deviceId = deviceInfo["deviceId"] as? Int32 else {
                    return nil
            }
            let linkData = LinkData(deviceName: deviceName, deviceType: deviceType, randomId: randomId, kind: kind)
            linkData.deviceId = deviceId
            linkData.version = version
            return linkData
        }
        guard let deviceInfo = params["newDeviceInfo"] as? [String: Any],
            let deviceName = deviceInfo["deviceFriendlyName"] as? String,
            let deviceType = deviceInfo["deviceType"] as? Int,
            let randomId = (deviceInfo["session"] as? [String: Any])?["randomId"] as? String else {
                return nil
        }
        return LinkData(deviceName: deviceName, deviceType: deviceType, randomId: randomId, kind: kind)
    }
    
    enum Kind {
        case link
        case sync
    }
}
