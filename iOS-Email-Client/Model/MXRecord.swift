//
//  Device.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class MXRecord {
    var ttl = ""
    var type = ""
    var priority = 0
    var host = ""
    var destination = ""
    
    class func fromDictionary(data: [String: Any]) -> MXRecord {
        let newRecord = MXRecord()
        newRecord.ttl = data["TTL"] as! String
        newRecord.type = data["type"] as! String
        newRecord.priority = data["priority"] as! Int
        newRecord.host = data["host"] as! String
        newRecord.destination = data["pointsTo"] as! String
        
        return newRecord
    }
}
