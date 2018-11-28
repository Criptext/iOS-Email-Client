//
//  CustomPasscodeViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/24/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import PasscodeLock

class CustomPasscodeViewController: PasscodeLockViewController {
    
    var currentRetry = 0
    
    override func passcodeLockDidFail(_ lock: PasscodeLockType) {
        super.passcodeLockDidFail(lock)
        currentRetry += 1
        let attemptsLeft = Env.maxRetryAttempts - currentRetry
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
}
