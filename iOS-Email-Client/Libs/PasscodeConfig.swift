//
//  PasscodeConfig.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import PasscodeLock

class PasscodeConfig: PasscodeLockConfigurationType {
    var repository: PasscodeRepositoryType = PasscodeType()
    
    var passcodeLength: Int = 4
    
    var isTouchIDAllowed: Bool = UserDefaults.standard.bool(forKey: PIN.fingerprint.rawValue) || UserDefaults.standard.bool(forKey: PIN.faceid.rawValue)
    
    var shouldRequestTouchIDImmediately: Bool = true
    
    var maximumInccorectPasscodeAttempts: Int = Env.maxRetryAttempts
    
    internal class PasscodeType: PasscodeRepositoryType {
        var hasPasscode: Bool {
            let defaults = UserDefaults.standard
            return defaults.string(forKey: PIN.lock.rawValue) != nil
        }
        
        func save(passcode: String) {
            let defaults = UserDefaults.standard
            defaults.set(passcode, forKey: PIN.lock.rawValue)
        }
        
        func check(passcode: String) -> Bool {
            let defaults = UserDefaults.standard
            guard let pass = defaults.string(forKey: PIN.lock.rawValue) else {
                return false
            }
            return passcode == pass
        }
        
        func delete() {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: PIN.lock.rawValue)
        }
    }
}
