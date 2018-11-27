//
//  CustomPasscodeViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/24/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import PasscodeLock
import LocalAuthentication

class CustomPasscodeViewController: PasscodeLockViewController {
    
    var showSignOut = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "PIN Lock"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        
        touchIDButton?.setImage(UIImage(named: biometricType == .faceID ? "faceID" : "touchID"), for: .normal)
        signoutButton?.isHidden = !showSignOut
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
        forceOut(manually: false, message: "\nYou have reached the maximum PIN retries. Your data has been deleted from this device!")
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func signout(_ sender: Any) {
        showLogout()
    }
    
    func showLogout(){
        let logoutPopover = LogoutPopoverViewController()
        logoutPopover.onTrigger = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                return
            }
            weakSelf.confirmLogout()
        }
        self.presentPopover(popover: logoutPopover, height: 245)
    }
    
    func showLocalAuth(){
        touchIDButton?.isHidden = !(showSignOut && biometricType != .none && passcodeLock.configuration.isTouchIDAllowed)
    }
    
    func confirmLogout(){
        let groupDefaults = UserDefaults.init(suiteName: Env.groupApp)!
        guard let username = groupDefaults.string(forKey: "activeAccount"),
            let account = SharedDB.getAccountByUsername(username) else {
            self.showAlert(String.localize("Logout Error"), message: String.localize("Not signed in, please restart the app."), style: .alert)
            return
        }
        APIManager.logout(token: account.jwt) { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            if case .Unauthorized = responseData {
                weakSelf.forceOut()
                return
            }
            if case .Forbidden = responseData {
                weakSelf.presentPasswordPopover(myAccount: account)
                return
            }
            guard case .Success = responseData else {
                weakSelf.showAlert(String.localize("Logout Error"), message: String.localize("Unable to logout. Please try again"), style: .alert)
                return
            }
            weakSelf.forceOut(manually: true)
        }
    }
    
    func forceOut(manually: Bool = false, message: String = "This device has been removed remotely."){
        self.logout(manually: manually, message: message)
        self.cancelButtonTap(self.cancelButton!)
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
