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
        navigationItem.title = String.localize("PIN_LOCK");
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
            let defaults = CriptextDefaults()
            return defaults.pinAttempts
        }
    }
    
    override func passcodeLockDidSucceed(_ lock: PasscodeLockType) {
        super.passcodeLockDidSucceed(lock)
        descriptionLabel!.text = String.localize("ENTER_PASSCODE")
    }
    
    override func passcodeLockDidFail(_ lock: PasscodeLockType) {
        super.passcodeLockDidFail(lock)
        let attemptsLeft = Env.maxRetryAttempts - incorrectPasscodeAttempts
        if (attemptsLeft > 3) {
            descriptionLabel!.text = String.localize("INCORRECT_ATTEMPTS_LEFT", arguments: attemptsLeft)
        } else if (attemptsLeft > 1) {
            descriptionLabel!.text = String.localize("WARNING_ATTEMPTS", arguments: attemptsLeft)
        } else {
            descriptionLabel!.text = String.localize("WARNING_ATTEMPT", arguments: attemptsLeft)
        }
        guard attemptsLeft <= 0 else {
            return
        }
        forceOut(manually: false, message: String.localize("MAX_PIN_ACCOUNT_DELETE"))
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func signout(_ sender: Any) {
        showLogout()
    }
    
    func showLogout(){
        let logoutPopover = GenericDualAnswerUIPopover()
        logoutPopover.initialTitle = String.localize("SIGNOUT")
        logoutPopover.initialMessage = String.localize("Q_SURE_LOGOUT")
        logoutPopover.leftOption = String.localize("CANCEL")
        logoutPopover.rightOption = String.localize("YES")
        logoutPopover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            weakSelf.confirmLogout()
        }
        self.presentPopover(popover: logoutPopover, height: 175)
    }
    
    func showLocalAuth(){
        touchIDButton?.isHidden = !(showSignOut && biometricType != .none && passcodeLock.configuration.isTouchIDAllowed)
    }
    
    func confirmLogout(){
        let defaults = CriptextDefaults()
        guard let username = defaults.activeAccount,
            let account = SharedDB.getAccountByUsername(username) else {
            self.showAlert(String.localize("SIGNOUT_ERROR"), message: String.localize("RESTART_APP"), style: .alert)
            return
        }
        APIManager.logout(account: account) { [weak self] (responseData) in
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
                weakSelf.showAlert(String.localize("SIGNOUT_ERROR"), message: String.localize("UNABLE_SIGNOUT"), style: .alert)
                return
            }
            weakSelf.forceOut(manually: true)
        }
    }
    
    func forceOut(manually: Bool = false, message: String = String.localize("REMOVED_REMOTELY")){
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
