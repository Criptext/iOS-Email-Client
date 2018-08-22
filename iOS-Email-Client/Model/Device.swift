//
//  Device.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Device {
    var id = 1
    var name = ""
    var location = ""
    var active = false
    var type = Kind.ios.rawValue
    
    enum Kind : Int{
        case pc = 1
        case ios = 2
        case android = 3
        
        static var current: Kind {
            return .ios
        }
    }
    
    class func fromDictionary(data: [String: Any]) -> Device {
        let newDevice = Device()
        newDevice.type = data["deviceType"] as! Int
        newDevice.id = data["deviceId"] as! Int
        newDevice.name = data["deviceFriendlyName"] as! String
        return newDevice
    }
    
    class func createActiveDevice() -> Device {
        let device = Device()
        device.name = systemIdentifier()
        device.type = Device.Kind.current.rawValue
        device.active = true
        return device
    }
}
