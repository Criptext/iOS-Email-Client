//
//  Time.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class Time {
    
    static let ONE_HOUR: Int = 60 * 60
    
    class func remaining(seconds: Int64) -> String {
        let hoursLeft = Int(floor(Double(seconds/Int64(Time.ONE_HOUR))))
        let minutesLeft = Int(ceil(Double(seconds / 60)))
        return hoursLeft > 0 ? "\(hoursLeft) hours" : "\(minutesLeft) minutes"
    }
}
