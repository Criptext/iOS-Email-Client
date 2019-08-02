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
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var supportButton: UIButton!
    @IBOutlet weak var usernameTextField: TextField!
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var loginErrorLabel: UILabel!
    var loggedOutRemotely: String?
    var multipleAccount = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        loginButtonInit()
        usernameTextFieldInit()
        supportButtonInit()
        
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        toggleLoadingView(false)
        clearErrors()
        checkToEnableDisableLoginButton()
        closeButton.isHidden = !multipleAccount
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
        let placeholderAttrs = [.foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)] as [NSAttributedString.Key: Any]
        usernameTextField.placeholderAnimation = .hidden
        usernameTextField.attributedPlaceholder = NSAttributedString(string: String.localize("EMAIL"), attributes: placeholderAttrs)
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
        let attrs = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor : UIColor.white]
        let attributedString = NSMutableAttributedString(string:boldText, attributes:attrs)
    
        let normalText = String.localize("NOT_REGISTERED")
        let normalAttrs = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17), NSAttributedString.Key.foregroundColor : UIColor.white]
        let normalString = NSMutableAttributedString(string:normalText, attributes: normalAttrs)
    
        normalString.append(attributedString)
        signupButton.setAttributedTitle(normalString, for: .normal)
    }
    
    func supportButtonInit(){
        let boldText  = String.localize("CONTACT_SUPPORT")
        let attrs = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor : UIColor.white]
        let attributedString = NSMutableAttributedString(string:boldText, attributes:attrs)
        
        let normalText = String.localize("HAVING_TROUBLE")
        let normalAttrs = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17), NSAttributedString.Key.foregroundColor : UIColor.white]
        let normalString = NSMutableAttributedString(string:normalText, attributes: normalAttrs)
        
        normalString.append(attributedString)
        supportButton.setAttributedTitle(normalString, for: .normal)
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
        guard loadingView.isHidden,
            let input = usernameTextField.text,
            let usernameDomain = checkEmailInput(input),
            Utils.validateEmail("\(usernameDomain.0)@\(usernameDomain.1)") else {
                loginButton.isEnabled = false
                loginButton.alpha = 0.5
                return
        }
        loginButton.isEnabled = true
        loginButton.alpha = 1.0
    }
    
    @IBAction func onLoginPress(_ sender: Any) {
        guard let email = usernameTextField.text?.lowercased() else {
            return
        }
        toggleLoadingView(true)
        checkUsername(email)
    }
    
    func showWarningPopup(username: String, domain: String, previous: String) {
        let regularAttrs = [NSAttributedString.Key.font: Font.regular.size(14)!]
        let boldAttrs = [NSAttributedString.Key.font: Font.bold.size(14)!]
        let warningPopover = SignInWarningPopoverViewController()
        let attrText = NSMutableAttributedString(string: String.localize("SIGNIN_WARNING_1"), attributes: regularAttrs)
        let attrTextBold = NSAttributedString(string: String.localize("SIGNIN_WARNING_2"), attributes: boldAttrs)
        let attrText2 = NSAttributedString(string: String.localize("SIGNIN_WARNING_3"), attributes: regularAttrs)
        let attrTextBold2 = NSAttributedString(string: "\(previous)\n\n", attributes: boldAttrs)
        let attrText3 = NSAttributedString(string: String.localize("SIGNIN_WARNING_4"), attributes: regularAttrs)
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
            self?.linkBegin(username: username, domain: domain)
        }
        self.presentPopover(popover: warningPopover, height: 275)
    }
    
    func existingAccount(_ accountId: String) -> Account? {
        guard DBManager.getLoggedOutAccount(accountId: accountId) == nil else {
            return nil
        }
        guard let existingAccount = DBManager.getLoggedOutAccounts().first else {
            return nil
        }
        return existingAccount
    }
    
    func checkEmailInput(_ input: String) -> (String, String)? {
        guard input.contains("@") else {
            return (input, Env.domain.replacingOccurrences(of: "@", with: ""))
        }
        
        let emailSplit = input.split(separator: "@")
        guard let username = emailSplit.first?.description,
            let domain = emailSplit.last?.description  else {
                return nil
        }
        
        return (username, domain)
    }
    
    func checkUsername(_ email: String) {
        
        guard let usernameDomain = checkEmailInput(email) else {
            return
        }
        
        let username = usernameDomain.0
        let domain = usernameDomain.1
        let accountId = domain == Env.plainDomain ? username : "\(username)@\(domain)"
        
        guard !multipleAccount || !self.checkAccountExists(accountId: accountId) else {
                self.showLoginError(error: String.localize("ACCOUNT_EXISTS"))
                return
        }
        
        APIManager.checkLogin(username: username, domain: domain) { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            if case .EnterpriseSuspended = responseData {
                weakSelf.showLoginError(error: String.localize("ACCOUNT_SUSPENDED_LOGIN"))
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                weakSelf.showLoginError(error: error.description)
                return
            }
            guard case .Success = responseData else {
                weakSelf.showLoginError(error: String.localize("USERNAME_NOT"))
                return
            }
            guard let user = weakSelf.existingAccount(accountId) else {
                weakSelf.linkBegin(username: username, domain: domain)
                return
            }
            let previousEmail = "\(user.username.hideMidChars())@\(user.domain ?? Env.plainDomain)"
            weakSelf.showWarningPopup(username: username, domain: domain, previous: previousEmail)
        }
    }
    
    func checkAccountExists(accountId: String) -> Bool {
        guard let existingAccount = DBManager.getAccountById(accountId),
            existingAccount.isLoggedIn else {
                return false
        }
        return  true
    }
    
    func linkBegin(username: String, domain: String){
        let loginData = LoginData(username: username, domain: domain)
        APIManager.linkBegin(username: username, domain: domain) { (responseData) in
            if case .Missing = responseData {
                self.showLoginError(error: String.localize("USERNAME_NOT"))
                return
            }
            if case .BadRequest = responseData {
                self.jumpToLoginPasswordView(loginData: loginData)
                return
            }
            if case .TooManyDevices = responseData {
                loginData.needToRemoveDevices = true
                self.jumpToLoginPasswordView(loginData: loginData)
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
    
    @IBAction func didPressSignup(sender: Any) {
        self.jumpToSignupDeviceView()
    }
    
    @IBAction func didPressContactSupport(sender: Any) {
        goToUrl(url: "https://criptext.com/\(Env.language)/contact")
    }
    
    @IBAction func didPressClose(sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showLoginError(error: String){
        self.setLoginError(error)
        self.toggleLoadingView(false)
    }
    
    func jumpToLoginPasswordView(loginData: LoginData){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "resetdeviceview")  as! ResetDeviceViewController
        controller.loginData = loginData
        controller.multipleAccount = self.multipleAccount
        navigationController?.pushViewController(controller, animated: true)
        toggleLoadingView(false)
        clearErrors()
    }
    
    func jumpToLoginDeviceView(loginData: LoginData){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "loginDeviceViewController")  as! LoginDeviceViewController
        controller.loginData = loginData
        controller.multipleAccount = self.multipleAccount
        navigationController?.pushViewController(controller, animated: true)
        toggleLoadingView(false)
        clearErrors()
    }
    
    func jumpToSignupDeviceView(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "signupview")  as! SignUpViewController
        controller.multipleAccount = self.multipleAccount
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
