//
//  TwoFactorAuthViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/28/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class TwoFactorAuthViewController: UIViewController {
    @IBOutlet weak var codeTextField: StatusTextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var creatingAccountLoadingView: CreatingAccountLoadingUIView!

    var loginData: LoginParams!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        creatingAccountLoadingView.display = false
        sendCode()
    }
    
    func sendCode() {
        APIManager.generateRecoveryCode(recipientId: loginData.username, domain: loginData.domain, token: loginData.jwt){ (responseData) in
            if case let .SuccessDictionary(data) = responseData {
                let emailAddress = data["address"] as? String ?? "No email address found"
                self.emailLabel.text = emailAddress
            } else if case .BadRequest = responseData {
                return
            } else {
                 return
            }
        }
    }
    
    @IBAction func onCodeChanged(_ sender: StatusTextField) {
        codeTextField.setStatus(.none)
        guard let code = sender.text,
              code.count == 6 else {
            return
        }
        validateCode()
    }
    
    @IBAction func onResendCode(_ sender: Any) {
        sendCode()
    }
    
    func validateCode() {
        let code = codeTextField.text!
        codeTextField.isEnabled = false
        APIManager.validateRecoveryCode(recipientId: loginData.username, domain: loginData.domain, code: code, token: loginData.jwt) { (responseData) in
            self.codeTextField.isEnabled = true
            guard case .SuccessDictionary = responseData else {
                self.codeTextField.setStatus(.invalid, String.localize("RECOVERY_CODE_DIALOG_ERROR"))
                return
            }
            self.codeTextField.resignFirstResponder()
            self.handleNext()
        }
    }
    
    func handleNext() {
        if (loginData.needToRemoveDevices) {
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
    
    func goToImportOptions(account: Account) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "importoptionsviewcontroller")  as! ImportOptionsViewController
        controller.myAccount = account
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func createAccount(loginData: LoginParams) {
        let loginManager = LoginManager(loginData: loginData)
        loginManager.delegate = self
        self.creatingAccountLoadingView.display = true
        loginManager.createAccount()
    }
    
    @IBAction func onBackPress(_ sender: UIButton) {
        goBack()
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
}

extension TwoFactorAuthViewController: LoginManagerDelegate {
    func handleResult(account: Account) {
        self.creatingAccountLoadingView.display = false
        self.goToImportOptions(account: account)
    }
    
    func throwError(message: String) {
        self.creatingAccountLoadingView.display = false
    }
}
