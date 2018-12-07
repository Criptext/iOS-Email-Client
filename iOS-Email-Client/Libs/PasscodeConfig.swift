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
    var incorrectPasscodeAttempts: Int {
        get {
            let defaults = CriptextDefaults()
            return defaults.pinAttempts
        }
        set {
            let defaults = CriptextDefaults()
            defaults.pinAttempts = newValue
        }
    }
    
    var repository: PasscodeRepositoryType = PasscodeType()
    
    var passcodeLength: Int = 4
    
    var isTouchIDAllowed: Bool = {
        let defaults = CriptextDefaults()
        return defaults.hasPIN && (defaults.hasFingerPrint || defaults.hasFaceID)
    }()
    
    var shouldRequestTouchIDImmediately: Bool = true
    
    var maximumInccorectPasscodeAttempts: Int = Env.maxRetryAttempts
    
    internal class PasscodeType: PasscodeRepositoryType {
        var hasPasscode: Bool {
            let defaults = CriptextDefaults()
            return defaults.hasPIN
        }
        
        func save(passcode: String) {
            let defaults = CriptextDefaults()
            defaults.pin = passcode
        }
        
        func check(passcode: String) -> Bool {
            let defaults = CriptextDefaults()
            guard let pass = defaults.pin else {
                return false
            }
            return passcode == pass
        }
        
        func delete() {
            let defaults = CriptextDefaults()
            defaults.removePasscode()
        }
    }
}
