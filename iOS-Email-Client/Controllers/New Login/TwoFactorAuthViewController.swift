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
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var creatingAccountLoadingView: CreatingAccountLoadingUIView!

    var loginData: LoginParams!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        creatingAccountLoadingView.display = false
        emailLabel.text = ""
        applyTheme()
        applyLocalization()
        sendCode()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.mainText
        emailLabel.textColor = theme.markedText
        codeTextField.applyMyTheme()
        
        self.view.backgroundColor = theme.overallBackground
        
        let attrString = NSMutableAttributedString(string: String.localize("2FA_DIDNT"), attributes: [.foregroundColor: theme.mainText, .font: Font.regular.size(resendButton.fontSize) as Any])
        attrString.append(NSAttributedString(string: String.localize("2FA_RESEND"), attributes: [.foregroundColor: theme.criptextBlue, .font: Font.bold.size(resendButton.fontSize) as Any]))
        resendButton.setAttributedTitle(attrString, for: .normal)
        
        codeTextField.attributedPlaceholder = NSAttributedString(string: String.localize("2FA_CODE"), attributes: [.foregroundColor: theme.secondText, .font: Font.regular.size(codeTextField.minimumFontSize) as Any])
    }
    
    func applyLocalization() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.text = String.localize("2FA_TITLE")
        messageLabel.text = String.localize("2FA_MESSAGE")
        
        let attrString = NSMutableAttributedString(string: String.localize("HAVING_TROUBLE"), attributes: [.foregroundColor: theme.mainText, .font: Font.regular.size(helpButton.fontSize) as Any])
        attrString.append(NSAttributedString(string: String.localize("CONTACT_SUPPORT"), attributes: [.foregroundColor: theme.criptextBlue, .font: Font.bold.size(helpButton.fontSize) as Any]))
        helpButton.setAttributedTitle(attrString, for: .normal)
    }
    
    @IBAction func onHelpPress(sender: Any) {
        goToUrl(url: "https://criptext.atlassian.net/servicedesk/customer/portals")
    }
    
    func sendCode() {
        APIManager.generateRecoveryCode(recipientId: loginData.username, domain: loginData.domain, token: loginData.jwt){ (responseData) in
            if case let .SuccessDictionary(data) = responseData {
                let emailAddress = data["address"] as? String ?? "No email address found"
                self.emailLabel.text = emailAddress
            } else if case let .BadRequestDictionary(data) = responseData {
                let emailAddress = data["address"] as? String ?? "No email address found"
                self.emailLabel.text = emailAddress
            } else {
                self.codeTextField.setStatus(.invalid, String.localize("SERVER_ERROR_RETRY"))
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
            guard case let .SuccessDictionary(data) = responseData else {
                self.codeTextField.setStatus(.invalid, String.localize("RECOVERY_CODE_DIALOG_ERROR"))
                return
            }
            if let newToken = data["token"] as? String {
                self.loginData.jwt = newToken
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
    
    func goBack(){
        let returnVC = self.navigationController?.viewControllers.first(where: { (vc) -> Bool in
            return vc.isKind(of: LoginViewController.self)
        })
        
        if let returnToVC = returnVC {
            self.navigationController?.popToViewController(returnToVC, animated: true)
        } else {
            self.navigationController?.popToRootViewController(animated: true)
        }
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
