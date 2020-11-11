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
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    var username = ""
    var domain = ""
    var oldPassword = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        creatingAccountLoadingView.display = false
        applyTheme()
        applyLocalization()
        checkButton()
    }
    
    @IBAction func onPasswordChanged(_ sender: StatusTextField) {
        passwordTextField.setStatus(.none)
        confirmPasswordTextField.setStatus(.none)
        checkButton()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        passwordTextField.isVisibilityIconButtonEnabled = true
        confirmPasswordTextField.isVisibilityIconButtonEnabled = true
        passwordTextField.applyMyTheme()
        confirmPasswordTextField.applyMyTheme()
        
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.mainText
        self.view.backgroundColor = theme.overallBackground
    }
    
    func applyLocalization() {
        let theme = ThemeManager.shared.theme
        
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("CONFIRM_PASSWORD"), attributes: [.font: Font.regular.size(confirmPasswordTextField.minimumFontSize)!, .foregroundColor: theme.secondText])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("PASSWORD"), attributes: [.font: Font.regular.size(passwordTextField.minimumFontSize)!, .foregroundColor: theme.secondText])
        
        let attrString = NSMutableAttributedString(string: String.localize("HAVING_TROUBLE"), attributes: [.foregroundColor: theme.mainText, .font: Font.regular.size(helpButton.fontSize) as Any])
        attrString.append(NSAttributedString(string: String.localize("CONTACT_SUPPORT"), attributes: [.foregroundColor: theme.criptextBlue, .font: Font.bold.size(helpButton.fontSize) as Any]))
        helpButton.setAttributedTitle(attrString, for: .normal)
        
        titleLabel.text = String.localize("CHANGE_TITLE")
        messageLabel.text = String.localize("CHANGE_MESSAGE")
    }
    
    @IBAction func onHelpPress(sender: Any) {
        goToUrl(url: "https://criptext.atlassian.net/servicedesk/customer/portals")
    }
    
    func checkButton() {
        guard let pass = passwordTextField.text,
              let confirmPass = confirmPasswordTextField.text else {
            continueButton.isEnabled = false
            continueButton.alpha = 0.5
            return
        }
        continueButton.isEnabled = pass.count >= 8 && confirmPass.count >= 8 && pass == confirmPass
        continueButton.alpha = continueButton.isEnabled ? 1 : 0.5
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
        passwordTextField.setStatus(.invalid)
        confirmPasswordTextField.setStatus(.invalid, message)
    }
    
    @IBAction func onBackPress(_ sender: UIButton) {
        goBack()
    }
    
    @objc func goBack(){
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
