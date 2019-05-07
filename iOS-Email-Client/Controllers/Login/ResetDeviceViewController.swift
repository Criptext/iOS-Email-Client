//
//  ResetDeviceViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/15/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class ResetDeviceViewController: UIViewController{

    let POPOVER_HEIGHT = 220
    let POPOVER_RECOVERY_HEIGHT = 225
    let POPOVER_NO_RECOVERY_HEIGHT = 255
    
    @IBOutlet weak var forgotButton: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var errorMark: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var resetLoaderView: UIActivityIndicatorView!
    var loginData: LoginData!
    var multipleAccount = false
    var failed = false
    var buttonTitle: String {
        return loginData.isTwoFactor ? String.localize("CONFIRM") : String.localize("SIGNIN")
    }
    
    override func viewDidLoad() {
        emailLabel.text = loginData.email
        resetLoaderView.isHidden = true
        showFeedback(false)
        checkToEnableDisableResetButton()
        let tap: UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        passwordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        passwordTextField.becomeFirstResponder()
        
        let placeholderAttrs = [.foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)] as [NSAttributedString.Key: Any]
        passwordTextField.placeholderAnimation = .hidden
        passwordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("PASSWORD"), attributes: placeholderAttrs)
        
        if(loginData.isTwoFactor){
            resetButton.setTitle(buttonTitle, for: .normal)
        }
    }
    
    @objc func onDonePress(_ sender: Any){
        if(resetButton.isEnabled){
            self.onResetPress(sender)
        }
    }
    
    @objc func hideKeyboard(){
        self.passwordTextField.endEditing(true)
    }
    
    @IBAction func onPasswordChange(_ sender: Any) {
        showFeedback(false)
        checkToEnableDisableResetButton()
    }
    
    @IBAction func onResetPress(_ sender: Any) {
        guard loginData.isTwoFactor else {
            loginRequest()
            return
        }
        loginAuth()
    }
    
    func loginRequest(){
        guard let password = passwordTextField.text else {
            return
        }
        showLoader(true)
        let email = loginData.email
        let username = String(email.split(separator: "@")[0])
        let domain = String(email.split(separator: "@")[1])
        APIManager.loginRequest(username: username, domain: domain, password: password.sha256()!) { (responseData) in
            self.showLoader(false)
            if case .TooManyDevices = responseData {
                self.showFeedback(true, String.localize("TOO_MANY_DEVICES"))
                return
            }
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
            let name = data["name"] as! String
            let deviceId = data["deviceId"] as! Int
            let token = data["token"] as! String
            let signupData = SignUpData(username: username, password: password, domain: domain, fullname: name, optionalEmail: nil)
            signupData.deviceId = deviceId
            signupData.token = token
            self.jumpToCreatingAccount(signupData: signupData)
        }
    }
    
    func loginAuth(){
        guard let password = passwordTextField.text,
            let jwt = loginData.jwt else {
            return
        }
        showLoader(true)
        var deviceInfo = Device.createActiveDevice(deviceId: 0).toDictionary(recipientId: loginData.username, domain: loginData.domain)
        deviceInfo["password"] = password.sha256()!
        APIManager.linkAuth(deviceInfo: deviceInfo, token: jwt) { (responseData) in
            self.showLoader(false)
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.showFeedback(true, error.description)
                return
            }
            if case .BadRequest = responseData {
                self.showFeedback(true, String.localize("WRONG_PASS_RETRY"))
                return
            }
            guard case .Success = responseData else {
                self.showFeedback(true, String.localize("SERVER_ERROR_RETRY"))
                return
            }
            self.loginData.password = password.sha256()!
            self.jumpToLoginDeviceView(loginData: self.loginData)
        }
    }
    
    func jumpToLoginDeviceView(loginData: LoginData){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "loginDeviceViewController")  as! LoginDeviceViewController
        controller.loginData = loginData
        controller.multipleAccount = self.multipleAccount
        navigationController?.pushViewController(controller, animated: true)
        showLoader(false)
    }
    
    @IBAction func textfieldDidEndOnExit(_ sender: Any) {
        if(resetButton.isEnabled){
            self.onResetPress(sender)
        }
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func checkToEnableDisableResetButton(){
        let textCount = passwordTextField.text?.count ?? 0
        resetButton.isEnabled = !(passwordTextField.isEmpty || textCount < Constants.MinCharactersPassword) && resetLoaderView.isHidden
        resetButton.setTitle(resetLoaderView.isHidden ? buttonTitle : "", for: .normal)
        if(resetButton.isEnabled){
            resetButton.alpha = 1.0
        }else{
            resetButton.alpha = 0.5
        }
    }
    
    func showFeedback(_ show: Bool, _ message: String? = nil){
        errorMark.isHidden = !show
        errorLabel.isHidden = !show
        if let errorMessage = message {
            labelHeightConstraint.constant = UIUtils.getLabelHeight(errorMessage, width: errorLabel.frame.width, fontSize: errorLabel.fontSize)
        }
        errorLabel.text = message ?? ""
    }
    
    func jumpToCreatingAccount(signupData: SignUpData){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "creatingaccountview") as! CreatingAccountViewController
        controller.signupData = signupData
        controller.multipleAccount = self.multipleAccount
        self.present(controller, animated: true, completion: nil)
    }
    
    func showLoader(_ show: Bool){
        resetLoaderView.isHidden = !show
        checkToEnableDisableResetButton()
        guard show else {
            resetLoaderView.stopAnimating()
            return
        }
        resetLoaderView.startAnimating()
    }
    
    @IBAction func onForgotPasswordPress(_ sender: Any) {
        sendResetLink()
    }
    
    func sendResetLink(){
        forgotButton.isEnabled = false
        let recipientId = loginData.username
        let domain = loginData.domain
        APIManager.resetPassword(username: String(recipientId), domain: domain) { (responseData) in
            self.forgotButton.isEnabled = true
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.presentResetAlert(height: self.POPOVER_HEIGHT, title: String.localize("REQUEST_ERROR"), message: error.description)
                return
            }
            if case .BadRequest = responseData {
                self.presentNoRecovery()
                return
            }
            guard case let .SuccessDictionary(data) = responseData,
                let email = data["address"] as? String else {
                    self.presentResetAlert(height: self.POPOVER_HEIGHT, title: String.localize("ODD"), message: String.localize("UNABLE_RECOVERY_RETRY"))
                    return
            }
            self.presentRecoveryEmail(email)
        }
    }
    
    func presentNoRecovery(){
        let regularAttr = [NSAttributedString.Key.font: Font.regular.size(14)!]
        let boldAttr = [NSAttributedString.Key.font: Font.bold.size(14)!]
        let attrText = NSMutableAttributedString(string: String.localize("RECOVER_IMPOSIBLE"), attributes: regularAttr)
        let attrBold = NSMutableAttributedString(string: "support@criptext.com", attributes: boldAttr)
        attrText.append(attrBold)
        self.presentResetAlert(height: POPOVER_NO_RECOVERY_HEIGHT, title: String.localize("No Recovery Email"), message: "", attributedText: attrText)
    }
    
    func presentRecoveryEmail(_ email: String){
        let regularAttr = [NSAttributedString.Key.font: Font.regular.size(14)!]
        let boldAttr = [NSAttributedString.Key.font: Font.bold.size(14)!]
        let attrText = NSMutableAttributedString(string: String.localize("RESET_LINK_SENT_1"), attributes: regularAttr)
        let attrBold = NSMutableAttributedString(string: "\(email)\n\n", attributes: boldAttr)
        let attrText2 = NSMutableAttributedString(string: String.localize("RESET_LINK_SENT_2"), attributes: regularAttr)
        attrText.append(attrBold)
        attrText.append(attrText2)
        self.presentResetAlert(height: POPOVER_RECOVERY_HEIGHT, title: String.localize("PASSWORD_RESET"), message: "", attributedText: attrText)
    }
    
    func presentResetAlert(height: Int, title: String, message: String, attributedText: NSAttributedString? = nil){
        let alertVC = GenericAlertUIPopover()
        alertVC.myTitle = title
        alertVC.myMessage = message
        alertVC.myAttributedMessage = attributedText
        self.presentPopover(popover: alertVC, height: height)
    }
}
