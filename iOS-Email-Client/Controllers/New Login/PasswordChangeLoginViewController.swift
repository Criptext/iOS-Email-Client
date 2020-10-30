//
//  PasswordChangeLoginViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/29/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class PasswordChangeLoginViewController: UIViewController {
    @IBOutlet weak var creatingAccountLoadingView: CreatingAccountLoadingUIView!
    @IBOutlet weak var confirmPasswordTextField: StatusTextField!
    @IBOutlet weak var passwordTextField: StatusTextField!
    @IBOutlet weak var continueButton: UIButton!
    
    var username = ""
    var domain = ""
    var password = ""
    var oldPassword = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkButton()
    }
    
    @IBAction func onPasswordChanged(_ sender: StatusTextField) {
        checkButton()
    }
    
    func checkButton() {
        guard let pass = passwordTextField.text,
              let confirmPass = confirmPasswordTextField.text else {
            continueButton.isEnabled = false
            return
        }
        continueButton.isEnabled = pass.count >= 8 && confirmPass.count > 8 && pass == confirmPass
    }
    
    @IBAction func onContinuePress(_ sender: Any) {
        guard let pass = passwordTextField.text else {
            return
        }
        APIManager.loginChangePasswordRequest(username: username, domain: domain, password: oldPassword.sha256()!, newPassword: pass.sha256()!) { (responseData) in
            if case let .TooManyRequests(waitingTime) = responseData {
                if waitingTime < 0 {
                    self.showFeedback(true, String.localize("TOO_MANY_SIGNIN"))
                } else {
                    self.showFeedback(true, String.localize("ATTEMPTS_TIME_LEFT", arguments: Time.remaining(seconds: waitingTime)))
                }
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.showFeedback(true, error.description)
                return
            }
            guard case let .SuccessString(dataString) = responseData,
                let data = Utils.convertToDictionary(text: dataString) else {
                    self.showFeedback(true, String.localize("WRONG_PASS_RETRY"))
                    return
            }
            self.handleResponseData(data: data, newPassword: pass)
        }
    }
    
    func handleResponseData(data: [String: Any], newPassword: String) {
        let loginData = LoginParams(username: username, domain: domain, password: newPassword, data: data)
        
        if (loginData.isTwoFactor) {
            goTo2FA(loginData: loginData)
        } else if (loginData.needToRemoveDevices) {
            goToRemoveDevices(loginData: loginData)
        } else {
            creatingAccountLoadingView.display = true
            createAccount(loginData: loginData)
        }
    }
    
    func goToRemoveDevices(loginData: LoginParams) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "deviceslimitviewcontroller")  as! DevicesLimitViewController
        controller.loginData = loginData
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func goTo2FA(loginData: LoginParams) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "twofactorauthviewcontroller")  as! TwoFactorAuthViewController
        controller.loginData = loginData
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func createAccount(loginData: LoginParams) {
        let loginManager = LoginManager(loginData: loginData)
        loginManager.delegate = self
        self.creatingAccountLoadingView.display = true
        loginManager.createAccount()
    }
    
    func goToImportOptions(account: Account) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "importoptionsviewcontroller")  as! ImportOptionsViewController
        controller.myAccount = account
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func showFeedback(_ show: Bool, _ message: String) {
        
    }
    
    @IBAction func onBackPress(_ sender: UIButton) {
        goBack()
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
}

extension PasswordChangeLoginViewController: LoginManagerDelegate {
    func handleResult(account: Account) {
        self.creatingAccountLoadingView.display = false
        self.goToImportOptions(account: account)
    }
    
    func throwError(message: String) {
        self.creatingAccountLoadingView.display = false
        self.showFeedback(true, message)
    }
}
