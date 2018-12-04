//
//  LightPasscodeViewController.swift
//  ShareExtension
//
//  Created by Allisson on 12/3/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit
import LocalAuthentication
import PasscodeLock

class LightPasscodeViewController: PasscodeLockViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        touchIDButton?.setImage(UIImage(named: biometricType == .faceID ? "faceID" : "touchID"), for: .normal)
    }
    
    override func appWillEnterForegroundHandler(_ notification: Notification) {
        super.appWillEnterForegroundHandler(notification)
        touchIDButton?.setImage(UIImage(named: biometricType == .faceID ? "faceID" : "touchID"), for: .normal)
        showLocalAuth()
    }
    
    var incorrectPasscodeAttempts: Int {
        get {
            return UserDefaults.standard.integer(forKey: "incorrectPasscodeAttemps")
        }
    }
    
    override func passcodeLockDidSucceed(_ lock: PasscodeLockType) {
        super.passcodeLockDidSucceed(lock)
        descriptionLabel!.text = "Enter your passcode to proceed."
    }
    
    override func passcodeLockDidFail(_ lock: PasscodeLockType) {
        super.passcodeLockDidFail(lock)
        let attemptsLeft = Env.maxRetryAttempts - incorrectPasscodeAttempts
        if (attemptsLeft > 3) {
            descriptionLabel!.text = "Incorrect PIN, \(attemptsLeft) attempts remaining"
        } else if (attemptsLeft > 1) {
            descriptionLabel!.text = "WARNING: \(attemptsLeft) attempts until secure data wipe"
        } else {
            descriptionLabel!.text = "WARNING: \(attemptsLeft) attempt until secure data wipe"
        }
        guard attemptsLeft <= 0 else {
            return
        }
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func signout(_ sender: Any) {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    func showLocalAuth(){
        touchIDButton?.isHidden = !(biometricType != .none && passcodeLock.configuration.isTouchIDAllowed)
    }
    
    enum BiometricType {
        case none
        case touchID
        case faceID
    }
    
    var biometricType: BiometricType {
        get {
            let context = LAContext()
            var error: NSError?
            
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                print(error?.localizedDescription ?? "")
                return .none
            }
            
            if #available(iOS 11.0, *) {
                switch context.biometryType {
                case .none:
                    return .none
                case .touchID:
                    return .touchID
                case .faceID:
                    return .faceID
                }
            } else {
                return  .touchID
            }
        }
    }
}
