//
//  GeneralSettingsData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class GeneralSettingsData {
    var recoveryEmail: String?
    var recoveryEmailStatus: RecoveryStatus = .none
    var isTwoFactor = false
    var hasEmailReceipts = false
    var password: String?
    
    enum RecoveryStatus {
        case pending
        case none
        case verified
        
        var description: String {
            switch(self){
            case .pending:
                return "Not Confirmed"
            case .none:
                return ""
            case .verified:
                return "Verified"
            }
        }
        
        var color: UIColor {
            switch(self){
            case .pending:
                return .alert
            case .none:
                return .white
            case .verified:
                return UIColor(red: 97/255, green: 185/255, blue: 0, alpha: 1)
            }
        }
    }
}
