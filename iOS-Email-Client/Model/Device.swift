//
//  Device.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift
import CoreBluetooth

class Device {
    var id = 1
    var name = ""
    var friendlyName = ""
    var location: String?
    var active = false
    var type = Kind.ios.rawValue
    var lastActivity: Date?
    
    enum Kind : Int{
        case pc = 1
        case ios = 2
        case android = 3
        
        static var current: Kind {
            return .ios
        }
    }
    
    func toDictionary(recipientId: String) -> [String: Any] {
        return [
            "recipientId": recipientId,
            "deviceName": self.name,
            "deviceFriendlyName": self.friendlyName,
            "deviceType": self.type
        ]
    }
    
    class func fromDictionary(data: [String: Any]) -> Device {
        let lastActivity = data["lastActivity"] as? [String: Any]
        let dateString = lastActivity?["date"] as? String
        let location = lastActivity?["ip"] as? String
        let newDevice = Device()
        newDevice.type = data["deviceType"] as! Int
        newDevice.id = data["deviceId"] as! Int
        newDevice.name = data["deviceName"] as! String
        newDevice.friendlyName = data["deviceFriendlyName"] as! String
        
        newDevice.lastActivity = dateString != nil ? EventData.convertToDate(dateString: dateString!) : nil
        newDevice.location = location
        return newDevice
    }
    
    class func createActiveDevice(deviceId: Int) -> Device {
        let device = Device()
        device.id = deviceId
        device.name = UIDevice.current.identifierForVendor!.uuidString
        device.friendlyName = UIDevice.current.name
        device.type = Device.Kind.current.rawValue
        device.active = true
        return device
    }
}
