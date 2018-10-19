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
    
    @IBOutlet weak var forgotButton: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var errorMark: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var resetLoaderView: UIActivityIndicatorView!
    var loginData: LoginData!
    var failed = false
    var buttonTitle: String {
        return loginData.isTwoFactor ? "Confirm" : "Sign-in"
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
        
        let placeholderAttrs = [.foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)] as [NSAttributedStringKey: Any]
        passwordTextField.placeholderAnimation = .hidden
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: placeholderAttrs)
        
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
        APIManager.loginRequest(username, password.sha256()!) { (responseData) in
            self.showLoader(false)
            if case .TooManyDevices = responseData {
                self.showFeedback(true, "Too many devices already logged in.")
                return
            }
            if case .TooManyRequests = responseData {
                self.showFeedback(true, "Too many sign in attempts, try again later.")
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.showFeedback(true, error.description)
                return
            }
            guard case let .SuccessString(dataString) = responseData,
                let data = Utils.convertToDictionary(text: dataString) else {
                    self.showFeedback(true, "Wrong password. Please try again.")
                    return
            }
            let name = data["name"] as! String
            let deviceId = data["deviceId"] as! Int
            let token = data["token"] as! String
            let signupData = SignUpData(username: username, password: password, fullname: name, optionalEmail: nil)
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
        var deviceInfo = Device.createActiveDevice(deviceId: 0).toDictionary(recipientId: loginData.username)
        deviceInfo["password"] = password.sha256()!
        APIManager.linkAuth(deviceInfo: deviceInfo, token: jwt) { (responseData) in
            self.showLoader(false)
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.showFeedback(true, error.description)
                return
            }
            if case .BadRequest = responseData {
                self.showFeedback(true, "Wrong password. Please try again.")
                return
            }
            guard case .Success = responseData else {
                self.showFeedback(true, "Server Error. Please try again.")
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
        errorLabel.text = message ?? ""
    }
    
    func jumpToCreatingAccount(signupData: SignUpData){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "creatingaccountview") as! CreatingAccountViewController
        controller.signupData = signupData
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
        let recipientId = loginData.email.split(separator: "@")[0]
        APIManager.resetPassword(username: String(recipientId)) { (responseData) in
            self.forgotButton.isEnabled = true
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.presentResetAlert(title: "Request Error", message: error.description)
                return
            }
            guard case let .SuccessDictionary(data) = responseData,
                let email = data["address"] as? String else {
                    self.presentResetAlert(title: "Request Error", message: "A recovery email address has not been set up or confirmed for this account, without it you cannot reset the password")
                    return
            }
            self.presentResetAlert(title: "Reset Password", message: "An email was sent to \(Utils.maskEmailAddress(email: email)) with the instructions to reset your password.")
        }
    }
    
    func presentResetAlert(title: String, message: String){
        let alertVC = GenericAlertUIPopover()
        alertVC.myTitle = title
        alertVC.myMessage = message
        self.presentPopover(popover: alertVC, height: POPOVER_HEIGHT)
    }
}
