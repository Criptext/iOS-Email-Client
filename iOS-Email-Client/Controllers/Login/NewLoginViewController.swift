//
//  NewLoginViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/2/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class NewLoginViewController: UIViewController{
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var usernameTextField: TextField!
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var loginErrorLabel: UILabel!
    var loggedOutRemotely: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        loginButtonInit()
        usernameTextFieldInit()
        
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        toggleLoadingView(false)
        clearErrors()
        checkToEnableDisableLoginButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let removeMessage = loggedOutRemotely {
            loggedOutRemotely = nil
            showAlert(String.localize("SIGNED_OUT"), message: String.localize(removeMessage), style: .alert)
        }
    }
    
    @objc func hideKeyboard(){
        self.usernameTextField.endEditing(true)
    }
    
    func usernameTextFieldInit(){
        let placeholderAttrs = [.foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)] as [NSAttributedStringKey: Any]
        usernameTextField.placeholderAnimation = .hidden
        usernameTextField.attributedPlaceholder = NSAttributedString(string: String.localize("USERNAME"), attributes: placeholderAttrs)
        usernameTextField.delegate = self
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.font = Font.regular.size(17.0)
        usernameTextField.textColor = UIColor.white
        usernameTextField.dividerNormalColor = UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
        usernameTextField.dividerActiveColor = UIColor.white
        usernameTextField.placeholderActiveScale = 0
        usernameTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
    }
    
    func loginButtonInit(){
        loginButton.clipsToBounds = true
        loginButton.layer.cornerRadius = 20
        
        let boldText  = String.localize("SIGNUP")
        let attrs = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 17), NSAttributedStringKey.foregroundColor : UIColor.white]
        let attributedString = NSMutableAttributedString(string:boldText, attributes:attrs)
    
        let normalText = String.localize("NOT_REGISTERED")
        let normalAttrs = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17), NSAttributedStringKey.foregroundColor : UIColor.white]
        let normalString = NSMutableAttributedString(string:normalText, attributes: normalAttrs)
    
        normalString.append(attributedString)
        signupButton.setAttributedTitle(normalString, for: .normal)
    }
    
    @objc func onDonePress(_ sender: Any){
        guard loginButton.isEnabled else {
            return
        }
        self.onLoginPress(sender)
    }
    
    func toggleLoadingView(_ show: Bool){
        if(show){
            loginButton.setTitle("", for: .normal)
            loadingView.isHidden = false
            loadingView.startAnimating()
        }else{
            loginButton.setTitle(String.localize("SIGNIN"), for: .normal)
            loadingView.isHidden = true
            loadingView.stopAnimating()
        }
        checkToEnableDisableLoginButton()
    }
    
    @IBAction func usernameChange(_ sender: Any) {
        checkToEnableDisableLoginButton()
        if(!errorImage.isHidden){
            clearErrors()
        }
    }
    
    func checkToEnableDisableLoginButton(){
        loginButton.isEnabled = !usernameTextField.isEmpty
        if(loginButton.isEnabled && loadingView.isHidden){
            loginButton.alpha = 1.0
        }else{
            loginButton.alpha = 0.5
        }
    }
    
    @IBAction func onLoginPress(_ sender: Any) {
        guard let username = usernameTextField.text?.lowercased() else {
            return
        }
        toggleLoadingView(true)
        checkUsername(username)
    }
    
    func showWarningPopup(username: String, previous: String) {
        let regularAttrs = [NSAttributedString.Key.font: Font.regular.size(14)!]
        let boldAttrs = [NSAttributedString.Key.font: Font.bold.size(14)!]
        let warningPopover = SignInWarningPopoverViewController()
        let attrText = NSMutableAttributedString(string: "SIGNIN_WARNING_1", attributes: regularAttrs)
        let attrTextBold = NSAttributedString(string: "SIGNIN_WARNING_2", attributes: boldAttrs)
        let attrText2 = NSAttributedString(string: "SIGNIN_WARNING_3", attributes: regularAttrs)
        let attrTextBold2 = NSAttributedString(string: "\(previous.hideMidChars())\(Env.domain)\n\n", attributes: boldAttrs)
        let attrText3 = NSAttributedString(string: "SIGNIN_WARNING_4", attributes: regularAttrs)
        attrText.append(attrTextBold)
        attrText.append(attrText2)
        attrText.append(attrTextBold2)
        attrText.append(attrText3)
        warningPopover.initialMessage = attrText
        warningPopover.shouldDismiss = false
        warningPopover.onTrigger = { [weak self] next in
            guard next else {
                self?.toggleLoadingView(false)
                return
            }
            self?.linkBegin(username: username)
        }
        self.presentPopover(popover: warningPopover, height: 275)
    }
    
    func existingAccount(_ username: String) -> String? {
        guard let existingAccount = DBManager.getFirstAccount(),
            existingAccount.username != username else {
            return nil
        }
        return existingAccount.username
    }
    
    func checkUsername(_ username: String) {
        APIManager.checkAvailableUsername(username) { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            if case .Success = responseData {
                weakSelf.showLoginError(error: String.localize("USERNAME_NOT"))
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                weakSelf.showLoginError(error: error.description)
                return
            }
            guard let user = weakSelf.existingAccount(username) else {
                weakSelf.linkBegin(username: username)
                return
            }
            weakSelf.showWarningPopup(username: username, previous: user)
        }
    }
    
    func linkBegin(username: String){
        let email = "\(usernameTextField.text!.lowercased())\(Constants.domain)"
        let loginData = LoginData(email)
        APIManager.linkBegin(username: username) { (responseData) in
            if case .Missing = responseData {
                self.showLoginError(error: String.localize("USERNAME_NOT"))
                return
            }
            if case .BadRequest = responseData {
                self.jumpToLoginPasswordView(loginData: loginData)
                return
            }
            if case .TooManyDevices = responseData {
                self.showLoginError(error: String.localize("TOO_MANY_DEVICES"))
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.showLoginError(error: error.description)
                return
            }
            guard case let .SuccessDictionary(data) = responseData,
                let twoFactor = data["twoFactorAuth"] as? Bool,
                let jwtTemp = data["token"] as? String else {
                self.showLoginError(error: String.localize("FALLBACK_ERROR"))
                return
            }
            loginData.jwt = jwtTemp
            guard twoFactor else {
                self.jumpToLoginDeviceView(loginData: loginData)
                return
            }
            
            loginData.isTwoFactor = true
            self.jumpToLoginPasswordView(loginData: loginData)
        }
    }
    
    @IBAction func textfieldDidEndOnExit(_ sender: Any) {
        guard loginButton.isEnabled else {
            return
        }
        self.onLoginPress(sender)
    }
    
    func showLoginError(error: String){
        self.setLoginError(error)
        self.toggleLoadingView(false)
    }
    
    func jumpToLoginPasswordView(loginData: LoginData){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "resetdeviceview")  as! ResetDeviceViewController
        controller.loginData = loginData
        navigationController?.pushViewController(controller, animated: true)
        toggleLoadingView(false)
        clearErrors()
    }
    
    func jumpToLoginDeviceView(loginData: LoginData){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "loginDeviceViewController")  as! LoginDeviceViewController
        controller.loginData = loginData
        navigationController?.pushViewController(controller, animated: true)
        toggleLoadingView(false)
        clearErrors()
    }
    
    func setLoginError(_ message: String){
        errorImage.isHidden = false
        loginErrorLabel.isHidden = false
        loginErrorLabel.text = message
    }
    
    func clearErrors(){
        errorImage.isHidden = true
        loginErrorLabel.isHidden = true
    }
}

extension NewLoginViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension NewLoginViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
