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
    
    weak var sharingViewController: UIViewController?
    @IBOutlet weak var numbersContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        touchIDButton?.setImage(UIImage(named: biometricType == .faceID ? "faceID" : "touchID"), for: .normal)
        handleMessageLabel()
    }
    
    override func appWillEnterForegroundHandler(_ notification: Notification) {
        super.appWillEnterForegroundHandler(notification)
        touchIDButton?.setImage(UIImage(named: biometricType == .faceID ? "faceID" : "touchID"), for: .normal)
        handleMessageLabel()
        showLocalAuth()
    }
    
    var incorrectPasscodeAttempts: Int {
        get {
            let defaults = CriptextDefaults()
            return defaults.pinAttempts
        }
    }
    
    override func passcodeLockDidSucceed(_ lock: PasscodeLockType) {
        super.passcodeLockDidSucceed(lock)
        descriptionLabel!.text = String.localize("PasscodeLockEnterDescription")
    }
    
    override func passcodeLockDidFail(_ lock: PasscodeLockType) {
        super.passcodeLockDidFail(lock)
        handleMessageLabel()
        
    }
    
    func handleMessageLabel() {
        numbersContainer.isUserInteractionEnabled = true
        let attemptsLeft = Env.maxRetryAttempts - incorrectPasscodeAttempts - 5
        if (attemptsLeft > 1) {
            descriptionLabel!.text = String.localize("INCORRECT_ATTEMPTS_LEFT", arguments: attemptsLeft)
        } else if (attemptsLeft == 1) {
            descriptionLabel!.text = String.localize("WARNING_SHARING")
        } else {
            numbersContainer.isUserInteractionEnabled = false
            descriptionLabel!.text = String.localize("WARNING_SHARING_DISABLE")
        }
    }
    
    @IBAction func signout(_ sender: Any) {
        closeExtension()
    }
    
    func closeExtension() {
        guard let presentingVC = sharingViewController as? ShareViewController,
            let extensionContext = presentingVC.extensionContext else {
                return
        }
        extensionContext.completeRequest(returningItems: nil, completionHandler: nil)
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
                @unknown default:
                    return .none
                }
            } else {
                return  .touchID
            }
        }
    }
}
