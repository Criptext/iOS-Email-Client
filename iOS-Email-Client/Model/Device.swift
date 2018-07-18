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
    @objc dynamic var uuid = ""
    @objc dynamic var name = ""
    @objc dynamic var location = ""
    @objc dynamic var active = false
    @objc dynamic var type = Kind.phone.rawValue
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    enum Kind : Int{
        case pc = 1
        case phone = 2
        case tablet = 3
        
        static var current: Kind {
            switch(UIDevice.current.userInterfaceIdiom){
            case .pad:
                return .tablet
            default:
                return .phone
            }
        }
    }
}
