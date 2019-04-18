//
//  DateString.swift
//  iOS-Email-Client
//
//  Created by Allisson on 4/18/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class DateString {
    class func backup(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        return dateFormatter.string(from: date)
    }
}
