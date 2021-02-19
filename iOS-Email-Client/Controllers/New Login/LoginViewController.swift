//
//  LoginViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/27/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import FirebaseMessaging

class LoginViewController: UIViewController {
    @IBOutlet weak var usernameTextField: StatusTextField!
    @IBOutlet weak var passwordTextField: StatusTextField!
    @IBOutlet weak var creatingAccountLoadingView: CreatingAccountLoadingUIView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var forgotButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        creatingAccountLoadingView.display = false
        showLoading(false)
        
        usernameTextField.becomeFirstResponder()
        applyTheme()
        applyLocalization()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.mainText
        forgotButton.setTitleColor(theme.criptextBlue, for: .normal)
        
        self.view.backgroundColor = theme.overallBackground
        passwordTextField.isVisibilityIconButtonEnabled = true
        usernameTextField.applyMyTheme()
        passwordTextField.applyMyTheme()
    }
    
    func applyLocalization() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.text = String.localize("LOGIN_TITLE")
        messageLabel.text = String.localize("LOGIN_MESSAGE")
        
        usernameTextField.attributedPlaceholder = NSAttributedString(string: String.localize("USERNAME"), attributes: [.font: Font.regular.size(usernameTextField.minimumFontSize)!, .foregroundColor: theme.secondText])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("PASSWORD"), attributes: [.font: Font.regular.size(usernameTextField.minimumFontSize)!, .foregroundColor: theme.secondText])
        
        loginButton.setTitle(String.localize("LOGIN"), for: .normal)
        forgotButton.setTitle(String.localize("LOGIN_FORGOT"), for: .normal)
        
        let attrString = NSMutableAttributedString(string: String.localize("HAVING_TROUBLE"), attributes: [.foregroundColor: theme.mainText, .font: Font.regular.size(helpButton.fontSize) as Any])
        attrString.append(NSAttributedString(string: String.localize("CONTACT_SUPPORT"), attributes: [.foregroundColor: theme.criptextBlue, .font: Font.bold.size(helpButton.fontSize) as Any]))
        helpButton.setAttributedTitle(attrString, for: .normal)
    }
    
    @IBAction func onHelpPress(sender: Any) {
        goToUrl(url: "https://criptext.atlassian.net/servicedesk/customer/portals")
    }
    
    @IBAction func onForgotPress(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "resetpasswordviewcontroller")  as! ResetPasswordViewController
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func onLoginPress(_ sender: UIButton) {
        guard let input = usernameTextField.text,
              let password = passwordTextField.text else {
            return
        }
        
        guard !input.isEmpty && !password.isEmpty else {
            return
        }
        
        let inputSplit = input.split(separator: "@")
        let username = inputSplit.first!.description
        let domain = inputSplit.count > 1 ? inputSplit[1].description : Env.plainDomain
        
        resignKeyboard()
        showLoading(true)
        
        APIManager.loginRequest(username: username, domain: domain, password: password.sha256()!) { (responseData) in
            self.showLoading(false)
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
            if case .PreConditionFail = responseData {
                let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "passwordchangeloginviewcontroller") as! PasswordChangeLoginViewController
                controller.username = username
                controller.domain = domain
                controller.oldPassword = password
                self.navigationController?.pushViewController(controller, animated: true)
                return
            }
            guard case let .SuccessString(dataString) = responseData,
                let data = Utils.convertToDictionary(text: dataString) else {
                    self.showFeedback(true, String.localize("WRONG_PASS_RETRY"))
                    return
            }
            self.handleSuccessResponse(username: username, domain: domain, password: password, data: data)
        }
    }
    
    func handleSuccessResponse(username:  String, domain: String, password: String, data: [String: Any]) {
        let loginData = LoginParams(username: username, domain: domain, password: password, data: data)
        
        if (loginData.isTwoFactor) {
            goTo2FA(loginData: loginData)
        } else if (loginData.needToRemoveDevices) {
            goToRemoveDevices(loginData: loginData)
        } else {
            creatingAccountLoadingView.display = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.createAccount(loginData: loginData)
            }
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
        loginManager.createAccount()
    }
    
    func goToImportOptions(account: Account) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "importoptionsviewcontroller")  as! ImportOptionsViewController
        controller.myAccount = account
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func showFeedback(_ show: Bool, _ message: String? = nil){
        usernameTextField.setStatus(.invalid, message)
    }
    
    @IBAction func onBackPress(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    func showLoading(_ show: Bool) {
        if show {
            loadingView.startAnimating()
            loginButton.isEnabled = false
            loginButton.alpha = 0.5
            loginButton.setTitle("", for: .normal)
            usernameTextField.isEnabled = false
            passwordTextField.isEnabled = false
        } else {
            loadingView.stopAnimating()
            loginButton.isEnabled = true
            loginButton.alpha = 1
            loginButton.setTitle(String.localize("LOGIN"), for: .normal)
            usernameTextField.isEnabled = true
            passwordTextField.isEnabled = true
        }
    }
    
    func resignKeyboard() {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
}

extension LoginViewController: LoginManagerDelegate {
    func handleResult(accountId: String) {
        guard let account = DBManager.getAccountById(accountId) else {
            return
        }
        self.creatingAccountLoadingView.display = false
        self.goToImportOptions(account: account)
    }
    
    func throwError(message: String) {
        self.creatingAccountLoadingView.display = false
        self.showFeedback(true, message)
    }
}
