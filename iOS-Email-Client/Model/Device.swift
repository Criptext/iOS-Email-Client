//
//  Device.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Device: Object {
    @objc dynamic var id = 1
    @objc dynamic var name = ""
    @objc dynamic var location = ""
    @objc dynamic var active = false
    @objc dynamic var type = Kind.ios.rawValue
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
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
}
