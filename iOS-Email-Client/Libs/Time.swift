//
//  Time.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class Time {
    
    static let ONE_MINUTE: Double = 60
    static let FIVE_MINUTES: Double = 60 * 5
    static let FIFTEEN_MINUTES: Double = 60 * 15
    static let ONE_HOUR: Double = 60 * 60
    static let ONE_DAY: Double = 60 * 60 * 24
    
    class func remaining(seconds: Int64) -> String {
        let hoursLeft = Int(floor(Double(seconds/Int64(Time.ONE_HOUR))))
        let minutesLeft = Int(ceil(Double(seconds / 60)))
        return "\(hoursLeft > 0 ? "\(hoursLeft) \(String.localize("HOURS")) " : "")\(minutesLeft > 0 ? "\(minutesLeft) \(String.localize("MINUTES"))" : "")"
    }
}
