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
        navigationItem.title = String.localize("PIN_LOCK_TITLE");
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        
        touchIDButton?.setImage(UIImage(named: biometricType == .faceID ? "faceID" : "touchID"), for: .normal)
        signoutButton?.isHidden = !showSignOut
        signoutButton?.setAttributedTitle(NSAttributedString(string: String.localize("PIN_SIGN_OUT"), attributes: [NSAttributedString.Key.font: Font.regular.size(17)!, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.foregroundColor: UIColor.white]), for: .normal)
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
        let defaults = CriptextDefaults()
        guard let accountId = defaults.activeAccount,
            let account = SharedDB.getAccountById(accountId) else {
                return
        }
        forceOut(account: account, manually: false, message: String.localize("MAX_PIN_ACCOUNT_DELETE"))
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func signout(_ sender: Any) {
        showLogout()
    }
    
    func showLogout(){
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("SIGNOUT")
        popover.initialMessage = String.localize("Q_SURE_LOGOUT")
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("YES")
        popover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            weakSelf.confirmLogout()
        }
        self.presentPopover(popover: popover, height: 175)
    }
    
    func showLocalAuth(){
        touchIDButton?.isHidden = !(showSignOut && biometricType != .none && passcodeLock.configuration.isTouchIDAllowed)
    }
    
    func confirmLogout(){
        let defaults = CriptextDefaults()
        guard let accountId = defaults.activeAccount,
            let account = SharedDB.getAccountById(accountId) else {
            self.showAlert(String.localize("SIGNOUT_ERROR"), message: String.localize("RESTART_APP"), style: .alert)
            return
        }
        APIManager.logout(token: account.jwt) { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            if case .Unauthorized = responseData {
                weakSelf.forceOut(account: account)
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
            weakSelf.forceOut(account: account, manually: true)
        }
    }
    
    func forceOut(account: Account, manually: Bool = false, message: String = String.localize("REMOVED_REMOTELY")){
        self.logout(account: account, manually: manually, message: message)
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
