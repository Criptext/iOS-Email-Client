//
//  PasscodeConfig.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import PasscodeLock

class PasscodeConfig: PasscodeLockConfigurationType {
    var repository: PasscodeRepositoryType = PasscodeType()
    
    var passcodeLength: Int = 4
    
    var isTouchIDAllowed: Bool = true
    
    var shouldRequestTouchIDImmediately: Bool = false
    
    var maximumInccorectPasscodeAttempts: Int = 5
    
    internal class PasscodeType: PasscodeRepositoryType {
        var hasPasscode: Bool {
            let defaults = UserDefaults.standard
            return defaults.string(forKey: "lock") != nil
        }
        
        func save(passcode: String) {
            let defaults = UserDefaults.standard
            defaults.set(passcode, forKey: "lock")
        }
        
        func check(passcode: String) -> Bool {
            let defaults = UserDefaults.standard
            guard let pass = defaults.string(forKey: "lock") else {
                return false
            }
            return passcode == pass
        }
        
        func delete() {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "lock")
        }
    }
}
